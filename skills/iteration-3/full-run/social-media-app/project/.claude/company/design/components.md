# Component Hierarchy: Picstory

## Layout
- AppLayout (Header, Main, BottomNav)
  - Header (Logo, NavIcons — Search, Create, Notifications, Profile)
  - BottomNav (Home, Search, Create, Notifications, Profile) — mobile only
  - Sidebar (NavLinks) — desktop only

## Auth Components
- LoginForm (email input, password input, submit button, register link)
- RegisterForm (email, username, password, confirm password, submit, login link)

## Post Components
- PostCard (PostHeader, PostImage, PostActions, PostCaption, PostComments)
  - PostHeader (avatar, username, menu dots)
  - PostImage (responsive image)
  - PostActions (LikeButton, CommentButton, like count)
  - PostCaption (username, caption text)
  - PostCommentPreview (comment count link)
- PostDetail (PostCard + full comments list + comment input)
- PostCreateForm (image upload, caption input, submit)
- PostGrid (3-column grid for profile page)

## Profile Components
- ProfileHeader (avatar, stats: posts/followers/following, bio, action button)
- ProfileStats (post count, follower count, following count)
- FollowButton (follow/unfollow toggle)
- ProfileEditForm (avatar upload, display name, bio, username)

## Social Components
- LikeButton (heart icon, animated toggle)
- CommentForm (text input + submit)
- CommentItem (avatar, username, content, time)
- CommentList (scrollable list of CommentItem)

## Notification Components
- NotificationList (list of NotificationItem)
- NotificationItem (avatar, message, time, read/unread indicator)

## Search Components
- SearchBar (input with search icon)
- UserSearchResult (avatar, username, display name, follow button)

## Shared UI Components
- Button (variants: primary, secondary, ghost, danger; sizes: sm, md, lg)
- Input (types: text, email, password; states: default, focus, error, disabled)
- Avatar (sizes: sm, md, lg, xl; fallback to initials)
- Card (container with shadow and rounded corners)
- Modal (overlay, title, content, actions)
- Toast (success, error, warning, info)
- LoadingSpinner
- EmptyState (icon, title, description)
- InfiniteScroll (scroll trigger for pagination)
