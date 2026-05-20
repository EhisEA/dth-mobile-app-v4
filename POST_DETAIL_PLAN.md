# Post Detail — Implementation Plan

Pairs with `POST_DETAIL_API_GAPS.md`. This is what we build **now** with
the existing API, structured so the deferred pieces (reactions, share,
structured author, pagination, sort) slot in without rework.

## Scope

**In:**

- Tap a `PostCard` in the home feed → navigate to a `PostDetailView`.
- Detail screen renders: media, header, description, action row, comment
  list with composer, lazy-loaded replies with reply composer.
- Shared posts cache (Riverpod) keyed by `uid`. Home feed and detail screen
  both read/write the same map, so any future mutation (like, share, etc.)
  propagates everywhere automatically.

**Out (stubbed gracefully — see "Stubs" below):**

- Like toggle (post + comment) — endpoint doesn't exist.
- Share count increment — endpoint doesn't exist (native share sheet still
  works; the count just won't bump).
- Structured author with avatar — payload doesn't include it; keep current
  `title` heuristic + initial-circle avatar fallback.
- Comment sort dropdown — only "Most recent" supported by API.
- Infinite scroll on comments — pagination params undocumented.

## Architecture

### Folder layout

```
features/posts/
  models/
    post.dart                      // existing
    comment.dart                   // NEW — domain model used by UI
  view_models/
    post_detail_view_model.dart    // NEW — owns one detail screen's lifecycle
    posts_cache.dart               // NEW — shared Map<uid, Post> via Riverpod
  views/
    post_detail_view.dart          // NEW
  components/
    post_card.dart                 // existing — accept onTap
    post_header.dart               // NEW — extract from card
    post_actions.dart              // NEW — extract from card, accept callbacks
    post_media.dart                // existing
    post_description.dart          // existing
    comment_tile.dart              // NEW
    comment_composer.dart          // NEW
data/
  models/
    timeline_comment.dart          // NEW — fromJson for the API shape
  repo/
    post/
      post_repo.dart               // NEW — fetchPost(uid)
      post_repo_impl.dart
    comment/
      comment_repo.dart            // NEW — list/create comments + replies
      comment_repo_impl.dart
core/
  constants/api_routes.dart        // add post detail, comment, reply routes
  router/routing_constants.dart    // add /post/:uid
```

`TimelineRepo` stays as-is for the feed list — it already does its job.
The new `PostRepo` is for single-post operations (fetch, future like/share);
`CommentRepo` is scoped to comments + replies.

### State flow

```
HomeViewModel ──fetchTimeline──▶ writes posts into PostsCache
                                              │
                                              ▼
                                       PostsCache (uid → Post)
                                              ▲
                                              │ reads + writes
                                              │
PostDetailViewModel ──fetchPost──▶ refreshes one entry
                  └─fetchComments──▶ owns local comment list
```

- `PostsCache` is a Riverpod `StateNotifier<Map<String, Post>>`.
  Source of truth for post-level fields (counts, future viewer state).
- `HomeViewModel.loadTimeline` writes the fetched list into the cache,
  then exposes IDs (or a derived view) to the UI.
- `PostDetailViewModel(uid)` reads the cached `Post` for instant render,
  then calls `postRepo.fetchPost(uid)` to refresh and re-write the cache.
- Comment list is **owned by the detail VM**, not the cache — it's
  screen-scoped data, not shared state.

### Domain `Comment` model (UI-facing)

```dart
class Comment {
  final String uid;
  final String authorName;
  final String? avatarUrl;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final int replyCount;
  final bool viewerReacted;     // always false for now (#3 in gaps doc)
  final bool isReply;            // type == "reply"
  final String? parentUid;
}
```

Mapped from API payload by a private `_commentFromJson` in
`CommentRepoImpl`, same pattern as the existing `_timelinePostToPost`.

### Stubs (and how they unstub)

| Feature | Stub now | When endpoint lands |
|---|---|---|
| Post like | Heart renders count, tap shows "Reactions coming soon" toast | Swap toast for `postRepo.toggleReaction(uid)` + optimistic cache update |
| Comment like | Same as post like | Same swap |
| Post share | Tap opens native share sheet (no count bump) | Add `postRepo.markShared(uid)` after sheet dismisses |
| `viewer_reacted` | Hardcoded `false` everywhere | Read from payload; rest of UI already binds to it |
| Author block | Use `_parseTitle` heuristic + initial-circle avatar | Read `post.user.{full_name, avatar}` |
| Sort dropdown | Hide it (or render disabled with "Most recent" only) | Wire dropdown to `?sort=` param |
| Infinite scroll | Single-page load | Add cursor-based `loadMore` to `PostDetailViewModel` |

## Execution order

Each step is shippable on its own — no half-done state at any boundary.

### Step 1 — Component split: `PostHeader` + `PostActions`

- Extract the header `Row` (logo, "with" label, name, timeAgo) from
  `PostCard` into `post_header.dart` as `PostHeader(post: post)`.
- Extract the action row from `PostCard` into `post_actions.dart` as
  `PostActions({post, onLike, onComment, onShare})`. Promote `_ActionChip`
  into this file as private.
- `PostCard` accepts new optional callbacks: `onTap`, `onLike`, `onComment`,
  `onShare`. Defaults to no-ops; existing `home_view` call site unaffected.
- Run `flutter analyze`. No behavior change.

### Step 2 — `PostsCache` + `PostRepo.fetchPost`

- Create `posts_cache.dart` as a Riverpod `StateNotifier<Map<String, Post>>`
  with `upsert(Post)`, `upsertAll(Iterable<Post>)`, and `get(uid)`.
- Add `ApiRoute.timelinePostDetail(String uid)`.
- Create `PostRepo` with `Future<Post> fetchPost(String uid)`.
  Implementation parses the same JSON shape as the list response and
  reuses the existing `_timelinePostToPost` mapper (lift it out of the
  home view-model into a shared `post_mapper.dart` under data).
- `HomeViewModel.loadTimeline` and `refreshTimeline` call
  `postsCache.upsertAll(_posts)` after fetch. UI keeps reading from VM
  for now — cache is plumbing, not yet load-bearing.
- Run analyze.

### Step 3 — Routing + `PostDetailView` skeleton

- Add `NavigatorRoutes.postDetail = "/post/:uid"`.
- Wire it in the router with `uid` extracted from path params and the
  optional `Post` extra used as a seed.
- Create `PostDetailView`: `AppBar` (back), then `PostHeader`, `PostMedia`,
  `PostDescription` (full text, no Read More truncation since we're
  already on detail), `PostActions` with inert `onLike` (toast) and a
  working `onShare` (native share sheet).
- `PostDetailViewModel(uid, seedPost?)`:
  - Reads `postsCache.get(uid)` → starts with that Post.
  - Calls `postRepo.fetchPost(uid)` in `init`, writes result back to cache.
  - Exposes a `Post` getter that reads-through the cache.
- `PostCard` from home tap → `MobileNavigationService.push(postDetail, extra: post)`.
- Visual milestone: tappable detail screen with everything **except** comments.

### Step 4 — `CommentRepo` + comment list rendering

- `TimelineComment.fromJson` in `data/models/timeline_comment.dart`.
- `CommentRepo`: `listComments(postUid)`, `listReplies(commentUid)`.
- Domain mapper → `Comment` model in `features/posts/models/comment.dart`.
- `comment_tile.dart` renders one comment: avatar (network or initial-circle
  fallback), name, time, body, like+reply chips (likes inert).
- `PostDetailViewModel`: add `comments` list state + `loadComments()`.
- `PostDetailView`: append a `SliverList` of `CommentTile`s below the post.
- Tap "Replies (N)" expands → `loadReplies(commentUid)`, renders inline
  indented under the parent.
- No sort dropdown yet. No pagination.

### Step 5 — Comment composer + create

- `comment_composer.dart`: bottom-anchored input + send button. State =
  `(text, replyTo: Comment?)`. Empty `replyTo` = new top-level comment;
  set = reply.
- `PostDetailViewModel`:
  - `submitComment(text)` → `commentRepo.createComment(postUid, text)`.
    On success: prepend to list, increment `post.counts.comments` via
    `postsCache.upsert`. On failure: toast.
  - `submitReply(parentUid, text)` → `commentRepo.createReply(parentUid, text)`.
    On success: append to that comment's replies list, increment its
    `replyCount`. On failure: toast.
- Reply UI: tapping "Reply" on a comment sets `replyTo` and focuses the
  composer with a "Replying to @name" chip + cancel.
- Pull-to-refresh on the detail screen re-fetches post + comments.

### Step 6 — Polish + verify

- Empty state for no comments.
- Error state for failed comment fetch (retry button).
- Loading skeletons (reuse existing shimmer color).
- `flutter analyze` clean.
- Manual smoke: tap post → detail loads → post comment → reply →
  pull-to-refresh → back → home counts updated from cache.

## Risks / things to watch

- **Cache invalidation**: home feed currently re-fetches on pull-to-refresh
  and overwrites the cache. If detail had pending optimistic state, that
  could clobber. Mitigation: `upsert` should merge non-null fields rather
  than replace wholesale. Decide at step 2.
- **Detail VM lifecycle**: don't make `PostDetailViewModel` a global
  singleton — it's per-route. Use Riverpod `family<PostDetailViewModel, String>`
  keyed by `uid`, autoDispose so leaving the route releases the comment list.
- **Title parsing edge cases**: if a post `title` is empty or doesn't match
  `"X with Y"`, `_parseTitle` returns sketchy values. The header should
  fall back to a generic label rather than render an empty name.
- **Replies endpoint shape**: the create-reply response wraps the new
  comment in `data.replies` (singular object, plural noun). Mapper needs
  to handle both `data.reply` and `data.replies` defensively in case
  backend fixes it later.

## Definition of done (this iteration)

- A signed-in user can tap a post, see its detail, read comments,
  post a comment, and reply to a comment.
- All counts displayed match the latest server response.
- Likes and share-count-bump are visibly inert with a clear "coming soon"
  signal — never silently no-op.
- Home feed reflects any change made on detail (only the comment count
  bumps, until reactions/share land).
- `flutter analyze` reports no new issues.
