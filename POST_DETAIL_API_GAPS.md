# Post Detail — API Gaps for Backend

The post detail screen (mobile design refs DTH-Mobile-6/7/8) needs the following
backend changes. The May 2026 Postman dump unblocked **reactions, viewer state,
and comment sort**; the remaining gaps are **share, structured author, and
pagination**.

Resolved during review (no backend action needed):

- View count increments server-side on `GET /api/timeline-posts/:uid`.
- `media` is `null` for video posts, otherwise an array of image URLs. Confirmed.
- Edit/delete comment, realtime comments, reply-response envelope shape are all
  out of scope for this iteration.

---

## ✅ 1. Post & comment reactions endpoints — RESOLVED

Now available as **toggle** endpoints (single POST flips state):

```
POST /api/timeline-posts/:uid/react              → returns updated post
POST /api/timeline-posts/comments/:uid/react     → returns updated comment
```

Response includes the full post/comment with fresh `counts.reactions` and
`viewer_reacted`. Wired up in `PostRepo.toggleReaction` /
`CommentRepo.toggleReaction` and consumed by `PostDetailViewModel` with
optimistic flip + rollback.

## 2. Share endpoint (still blocking)

Design shows a share count. Need a way to bump it after the native share
sheet completes:

```
POST   /api/timeline-posts/:uid/share
```

Response: updated `counts.shares`.

Currently stubbed client-side as a "Share coming soon" toast.

## ✅ 3. `viewer_reacted` field on post + comment responses — RESOLVED

Now present on:

- `GET /api/timeline-posts` (post list)
- `GET /api/timeline-posts/:uid` (post detail)
- `GET /api/timeline-posts/:uid/comments` (comment list)
- `GET /api/timeline-posts/comments/:uid/replies` (replies list — implicit, not
  shown in the example response but assumed)
- `POST .../react` toggle responses

Parsed in `TimelinePost.fromJson` / `TimelineComment.fromJson` and surfaced
through the domain `Post.viewerReacted` / `Comment.viewerReacted`.

## 4. Structured author on post (still blocking)

Posts currently embed author in `title` ("X with Y"). The mobile client
parses this with a string heuristic (`parsePostTitle` in `post_mapper.dart`),
which is brittle and breaks on any title that doesn't follow the pattern.

Comments already have a clean `user` block — please add the same to posts:

```json
"user": {
  "full_name": "de9jaspirit",
  "avatar": "https://...",
  "verified": true
}
```

(`verified` is optional but the design shows a verification tick on the
post header.) Once present, `title` can stay as a free-form caption or be
removed if redundant.

## 7. Comment `user.username` (still blocking comment thread design)

The comment thread screen design (DTH-Mobile-10) shows an `@handle` under the
author name (e.g. "Banger Designer / @banger_designer"). The comment `user`
block currently exposes only `full_name` and `avatar`. Add:

```json
"user": {
  "full_name": "Banger Designer",
  "username": "banger_designer",
  "avatar": "https://..."
}
```

The Flutter client parses `user.username` already and hides the line when
absent — backend just needs to populate it.

## 8. Comment `counts.views` (still blocking comment thread design)

The comment thread screen shows "Posted 4h ago · 345k views" on the parent
comment. The comment `counts` block exposes `comments`, `reactions`, `shares`
but not `views`. Add:

```json
"counts": { "comments": 54, "reactions": 16000, "shares": 24, "views": 345000 }
```

The Flutter client parses `counts.views` already and hides the views segment
when zero.

---

## ✅ 5. Pagination — RESOLVED for posts, reels, comments, and replies

`GET /api/timeline-posts`, `GET /api/timeline-reels`, and
`GET /api/timeline-posts/:uid/comments` all return the same
cursor-paginated envelope:

```json
"data": {
  "<key>": {
    "data": [...],
    "path": "https://.../api/...",
    "per_page": 10,
    "next_cursor": "...",       // null when no more pages
    "next_page_url": "...",
    "prev_cursor": "...",
    "prev_page_url": "..."
  }
}
```

Wired up via `PaginatedResult<T>` in `data/models/paginated_result.dart`,
consumed by `TimelineRepo.fetchTimeline({String? cursor})`,
`TimelineRepo.fetchTimelineReels({String? cursor})`, and
`CommentRepo.listComments(uid, {String? cursor})`. The home VM exposes
`loadMoreTimeline()`; `PostDetailViewModel` exposes `loadMoreComments()`.
Both views trigger on scroll-near-bottom (~400px before `maxScrollExtent`)
with a footer spinner while fetching.

Replies (`GET /api/timeline-posts/comments/:uid/replies`) are wired the
same way; the client assumes the same envelope shape and parses
defensively — empty result if the envelope is missing. Confirm the
backend response when it's available.

## ✅ 6. Comment sort param — RESOLVED

Available via `?sort=latest|oldest` (not the `recent|top` we initially
proposed). The "Most recent ▾" dropdown in the design maps cleanly to
`latest`; the alternative is `oldest`. **No "top" sort exists yet** — flag
for future if engagement-based sorting becomes a requirement.

Default appears to be `latest` per the doc.

---

## Mobile-side notes (no backend action)

- **Cache-as-source-of-truth.** `PostsCache` (a `ChangeNotifier` keyed by
  post `uid`) holds every `Post` object. `HomeViewModel` stores **only the
  feed order** (`List<String> postUids`) and the home view derives the
  visible list with `uids.map(cache.get).whereType<Post>()`. The detail VM
  reads through the same cache. A like-toggle on detail mutates the cache,
  which broadcasts to anyone watching — home updates automatically with no
  sync code.
- Author parsing from `title` will be removed once #4 lands.
