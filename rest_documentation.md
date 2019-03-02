# Rest Documentation

This documentation is for the rest endpoints under /api/v2

## Global Query Parameters

* app=plain - If this is included in the query parameters, no HTML text formatting will be applied to marked_up_text. Returned text will be plain text instead. This is useful in any endpoint that returns stream post text, forum post text, or seamail text.

## Parameter Type Definitions

These parameter types are used throughout the API

* boolean - (true, false, 1, 0, yes, no)
* datetime_string - ISO 8601 date/time string, or milliseconds since the unix epoch as a string
* epoch - milliseconds since the unix epoch as an integer
* id_string - a string for the id
* username_string - user's username.  All lowercase word characters plus '-' and '&', at least 3 characters
* displayname_string - user's display name. All word characters plus '.', '&', '-', and space, at least 3 characters, max 40 characters.
* password_string - user's password. Minimum length 6 characters.
* role_string - one of the following roles: "admin", "tho", "moderator", "user", "muted", "banned"

## Output Type Definitions

These output types are used throughout the API

* UserInfo{} - A JSON object representing the most basic details of a user
  ```
  {
      "username": username_string
      "display_name": displayname_string
      "last_photo_updated": epoch
  }
  ```
* marked_up_text - A string with inline HTML. Allowed HTML is limited. If you do not want any HTML, include app=plain in your query parameters. This parameter will cause any marked_up_text to instead be returned as plain text. Examples of allowed tags:
  * a - Hashtags. Example for the hashtag, #some_tag
    * `<a class="tweet-url hashtag" href="#/tag/some_tag" title="#some_tag">#some_tag</a>` 
  * a - User mentions. Example for the user mention, @some_user
    * `<a class="tweet-url username" href="#/user/some_user">@some_user</a>`
  * img - Emoji. Example for the emoji, :buffet:
    * `<img src="/img/emoji/small/buffet.png" class="emoji" />`
    * Possible emoji: buffet|die-ship|die|fez|hottub|joco|pirate|ship-front|ship|towel-monkey|tropical-drink|zombie
  * br - Line breaks
    * `<br />`
    * If using app=plain, these will instead be returned as newline `\n`
* ReactionsSummary{} - A JSON object showing the counts of each reaction type. Will be { } if no reactions.
  ```
  {
      "reaction_word": {
          "count": \d+,
          "me": boolean # Will be true if current user has reacted with this reaction
      },
      ...
  }
  ```
* ReactionDetails{} - A JSON object with the details of an individual reaction
  ```
  {
      "reaction": string
      "user": UserInfo{}
  }
  ```
* PhotoDetails{} - A JSON object with the details of a photo
  ```
  {
      "id": "photo_id_string",
      "animated": boolean,
      "sizes": [PhotoSize{}, ...]
  }
  ```
* PhotoSize{} - A JSON object representing the resolution of a photo.
  ```
  {
      "size_string": "resolution_string"
  }
  ```
  * `size_string` will be "small_thumb", "medium_thumb", or "full"
  * `resolution_string` will be the photo's resolution, width x height. Example: "800x600"
* Announcement{} - A JSON object representing an announcement
  ```
  {
      "id": "id_string",
      "author": UserInfo{},
      "text": "string", # Marked up string
      "timestamp": epoch
  }
  ```

## Error Type Definitions
* status_code_only
  * HTTP status code with a blank response
* status_code_with_message
  * HTTP status code with JSON: a single error message
  ```
  { "status": "error", "error": "message" }
  ```
* status_code_with_error_list
  * HTTP status code with JSON: a list of error messages
  ```
  { "status": "error", "errors": [ "message1", ...] }
  ```
* status_code_with_parameter_errors
  * HTTP status code with JSON: a list of error messages associated to a parameter
  ```
  { 
    "status": "error", 
    "errors": {
        "parameter_name": [
            "message1", ...
        ], ...
    }
  }
  ```


## Seamail information

All seamail endpoints accept `as_mod` as a URL parameter. If you set `as_mod=true` on any seamail endpoint, and the current user has a Moderator, THO, or Admin role, the seamail endpoint will behave as if the user is currently logged in as the generic `moderator` account. If the current user is a regular user, sending `as_mod=true` will have no effect.

### Seamail specific types

#### SeamailMessage{}

```
{
    "id": "seamail_message_id_string",
    "author": UserInfo{},
    "text": "string",
    "timestamp": epoch, # Date and time that this message was posted
    "read_users": [
        UserInfo{}, ...
    ]
}
```

#### SeamailThread{}

```
{
    "id": "seamail_thread_id_string",
    "users": [ # All of the users participating in the thread
        UserInfo{}, ...
    ],
    "subject": "string",
    "messages": [ SeamailMessage{}, ...], # Sorted by message timestamp descending. Excluded from some endpoints that only return metadata.
    "message_count": integer # An integer counting the number of messages (or unread messages) in the thread
    "timestamp": epoch, # Date and time of the most recent message in the thread
    "count_is_unread": boolean # If true, message_count is the number of unread messages in the thread. If false, message_count is the number of all messages in the thread.
    "is_unread": boolean # If any message in the thread is unread, this will be true
}
```

Note about message_count: Normally, this is the count of all messages in the thread. However, if only returning unread messages (using an unread=true parameter in an endpoint which supports it), this will be the count of unread messages in the thread. If this is the case, count_is_unread will be set to true.

### GET /api/v2/seamail

Gets the User's seamail metadata (Not the messages contained within, just the subject, etc)

#### Requires

* logged in.
    * Accepts: key query parameter

#### Query parameters

* unread=boolean - Optional (Default: false) - only show unread seamail if true
* after=ISO_8601_DATETIME OR epoch - Optional (Default: all messages) - Only show seamail threads that have been updated after this point in time.
  * Tip: You can store last_checked from the results of this call, and pass it back as the value of the after parameter in your next call to this endpiont. You will only get threads created/updated since your last call. Useful if you are polling.

#### Returns

```
{
    "status": "ok",
    "seamail_meta": [ SeamailThread{ WITHOUT messages }, ... ],
    "last_checked": epoch # Server timestamp of when this call was made
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in

### GET /api/v2/seamail_threads

Gets the User's seamail threads, with messages included. This endpoint has three basic modes, which can be further modified by using the after parameter:
1. All threads with all messages - do not send unread or exclude_read_messages parameters
1. All threads, only unread messages - send exclude_read_messages=true
1. Unread threads, only unread messages - send unread=true

Note that sending both unread=true&exclude_read_messages=true will operate identically to the third mode.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Query parameters

* unread=true - Optional (Default: false) - If this parameter is included, only return threads with unread seamail, and only include unread messages in each thread.
* exclude_read_messages=true - Optional (Default: false) - If this parameter is included, return all threads, but only include unread messages in each thread.
* after=ISO_8601_DATETIME OR epoch - Optional (Default: all messages) - Only show seamail threads and messages after this point in time.
  * Tip: You can store last_checked from the results of this call, and pass it back as the value of the after parameter in your next call to this endpiont. You will only get threads and messages created since your last call. Useful if you are polling and storing the results client-side.

#### Returns

```
{
    "status": "ok",
    "seamail_threads": [ SeamailThread{}, ... ], 
    "last_checked": epoch # Server timestamp of when this call was made
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in

### GET /api/v2/seamail/:id_string

Gets the messages contained within a seamail

#### Requires

* logged in.
    * Accepts: key query parameter

#### Query parameters

* skip_mark_read=true - If this parameter is present, seamail will not be marked read as a result of this call. Default behavior is to mark the entire thread as read.

#### Returns

```
{
    "status": "ok",
    "seamail": SeamailThread{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message - HTTP 404 if the seamail is not found or the current user is not in the seamail recipients list
  ```
    { "status": "error", "error": "Seamail not found" }
  ```

### POST /api/v2/seamail

Creates a new Seamail, with a initial message

#### Requires

* logged in.
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "users": [username_string, ...],   # A list of recipient usernames. No need to include the author, it will be automatically added. Duplicates will be ignored.
    "subject": "string", # Max length: 200 characters, UTF-8.
    "text": "string"  # Max length: 10,000 characters, UTF-8. The first post's of the seamail's textual content.
}
```

#### Returns

```
{
    "status": "ok",
    "seamail": SeamailThread{}
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_error_list - HTTP 400 with a list of any problems
  ```
    {
        "status": "error",
        "errors": [
            "Must send seamail to another user of Twit-arr", # No users in the user list
            "x is not a valid username", # No user exists with the username 'x'
            "Subject can't be blank",
            "Subject is too long (maximum is 200 characters)",
            "Text can't be blank",
            "Text is too long (maximum is 10000 characters)"
        ]
    }
  ```

### POST /api/v2/seamail/:id

Add a new message to an existing Seamail thread

#### Requires

* logged in.
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "text": "string" # Max length: 10,000 characters, UTF-8.
}
```

#### Returns

```
{
    "status": "ok",
    "seamail_message": SeamailMessage{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if seamail with given ID is not found or user does not have access
    ```
    { "status": "error", "error": "Seamail not found" }
    ```
* status_code_with_error_list - HTTP 400
   ```
   { 
        "status": "error", 
        "errors": [ 
            "Text can't be blank",
            "Text is too long (maximum is 10000 characters)"
        ]
   }
   ```

### POST /api/v2/seamail/:id/recipients

Modifies the recipients of a seamail. Disabled until we figure out if/how we want to support this.

#### Requires

* logged in.
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "users": ["username_string", ...] # A list of recipient usernames. No need to include the author, it will be automatically added. Duplicates will be ignored.
}
```

#### Returns

```
{
    "status": "ok",
    "seamail_meta": SeamailThread{ WITHOUT messages }
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if seamail with given ID is not found or user does not have access
   ```
    { "status": "error", "error": "Seamail not found" }
   ```
* status_code_with_error_list - HTTP 400 with a list of any problems
   ```
    {
        "status": "error",
        "errors": [
            "Must send seamail to another user of Twit-arr", # No users in the user list
        ]
    }
   ```
### GET /api/v2/user/new_seamail

Get how many unread seamails the user has

#### Requires

* logged in.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "email_count": 0 # Integer count of unread seamails
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in


## Stream information

Get/post information on the tweet stream

### Stream specific types

#### StreamPost{}

```
{
    "id": "id_string",
    "author": UserInfo{},
    "locked": boolean,
    "timestamp": epoch,
    "text": "marked_up_text",
    "reactions": ReactionsSummary{},
    "photo": PhotoDetails{}, # photo will not be present if the post does not have a photo
    "parent_chain": [ "stream_post_id_string", ... ]
}
```

#### StreamPostThread{}

```
{
    "id": "id_string",
    "author": UserInfo{},
    "locked": boolean,
    "text": "marked up text",
    "timestamp": epoch,
    "reactions": ReactionsSummary{},
    "parent_chain": [ "stream_post_id_string", ... ],
    "photo": PhotoDetails{}, # photo will not be present if the post does not have a photo
    "children": [ # children will not be present if there are no child posts
        StreamPost{ WITHOUT parent_chain }, ...
    ]
}
```

### GET /api/v2/stream or /api/v2/stream/:start

Get the tweets in the stream. This is an incredibly flexible endpoint that will return a page of tweets (default 20, the `limit` parameter) either before or after (the `newer_posts` paramter) a given timestamp (the `start` parameter). If no `start` timestamp is given, it will return the `limit` most recent tweets.

#### Query parameters

* start=epoch - Optional (Default: Now) - The start location for getting tweets
* newer_posts=true - Optional (Default: false) - If this parameter is true, get tweets with timestamp >= start, otherwise get tweets with timestamp <= start
* limit=Integer - Optional (Default: 20) - How many tweets to get
* author=username - Optional (Default: No Filter) - Filter by username specified
* hashtag=hashtag - Optional (Default: No Filter) - Filter by hashtag
* mentions=username - Optional (Default: No Filter) - Filter by mentions of username specified
* include_author=true - Optional (Default: false) - When filtering by mentions, include posts mentioning *or* written by the username specified
* starred=true - Optional (Default: false) - Return only posts by starred users (You must be logged in for this to work.)
* reacted=true - Optional (Default: false) - Return only posts where the current user has reacted to the post (You must be logged in for this to work.)

#### Returns

```
{
    "status": "ok",
    "stream_posts": [ # Sorted by timestamp descending
        StreamPost{}, 
        ...
    ],
    "has_next_page": boolean,
    "next_page": epoch
}
```

Some notes on `newer_posts` in the input and `next_page` in the output: `next_page` is a timestamp that depends on the `newer_posts` parameter. `newer_posts` essentially controlls which direction through the tweet stream you are scrolling. `has_next_page` will be true if the server has more posts in the direction indicated by the `newer_posts` parameter at the time of the request.
* If `newer_posts=false`, the value of `next_page` will be the timestamp of the oldest tweet minus one millisecond. This will assist in going backwards in time through the tweet stream.
* If `newer_posts=true`, the value of `next_page` will be the timestamp of the youngest tweet returned plus one millisecond. This will assist in going forwards in time through the tweet stream.
* Hint: If you want to get the latest page of tweets and then poll (or refresh) for newer tweets, it is recommended to send a request without `start`, and with `newer_posts=true`. This will give you a timestamp that you can pass as the value of `start`, along with `newer_posts=true`. If there are new posts, you will get results, and a new value for `start` for future polling. However, you will need to calculate a value for scrolling backwards in time: take the timestamp of the last tweet, convert to milliseconds since the unix epoc, and subtract 1 millisecond. Use that calculated value as `start` with `newer_posts=false` to get previous pages. You will then be able to use the server-provided `next_page` value for even older pages.

#### Error Responses
* status_code_with_message
  * HTTP 400 if `limit < 1`
    ```
    {
        "status": "error",
        "error": "Limit must be greater than 0"
    }
    ```
  * HTTP 400 if a boolean parameter is given a bad value
    ```
    {
        "status": "error",
        "error": "Invalid value for Boolean: str" # str will be replaced with the invalid value
    }
    ```

### GET /api/v2/thread/:id

Get details of a stream post (tweet) with the given :id
This will include the children posts (replies) to this tweet sorted in timestamp order

#### Query parameters

* limit=Integer - Optional (Default: 20) - Number of child posts to return with the thread
* page=Integer - Optional (Default: 0) - The page of tweets to retrieve, zero-indexed. Multiplied by `limit` to determine number of tweets to skip.

#### Returns

```
{
    "status": "ok",
    "post": StreamPostThread{},
    "has_next_page": boolean
}
```

#### Error Responses
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```
* status_code_with_message
  * HTTP 400 if `limit < 1` or `page < 0`
    ```
    {
        "status": "error", 
        "error": "Limit must be greater than 0, Page must be greater than or equal to 0"
    }
    ```

### GET /api/v2/stream/m/:query

View a mentions stream. Will include all tweets that tag the user. :query is the username_string of the user whose mentions we want to view.

#### Query parameters

* limit=Integer - Optional (Default: 20) - Number of tweets to return
* page=Integer - Optional (Default: 0) - The page of tweets to retrieve, zero-indexed. Multiplied by `limit` to determine number of tweets to skip.
* after=epoch - Optional (Default: None) - Start time to query for (only showing tweets newer than this)

#### Returns

```
{
    "status": "ok", 
    "posts": [
        StreamPost{}, 
        ...
    ],
    "total": integer, # Total number of tweets that mention the user
    "has_next_page": boolean
}
```

#### Error Responses
* status_code_with_message
  * HTTP 400 if `limit < 1` or `page < 0`
    ```
    {
        "status": "error", 
        "error": "Limit must be greater than 0, Page must be greater than or equal to 0"
    }
    ```

### GET /api/v2/stream/h/:query

View a hash tag tweet stream. :query is the hashtag we would like to view.

#### Query parameters

* limit=Integer - Optional (Default: 20) - Number of tweets to return
* page=Integer - Optional (Default: 0) - The page of tweets to retrieve, zero-indexed. Multiplied by `limit` to determine number of tweets to skip.
* after=epoch - Optional (Default: None) - Start time to query for (only showing tweets newer than this)

#### Returns

```
{
    "status": "ok", 
    "posts": [
        StreamPost{}, 
        ...
    ],
    "total": integer, # Total number of tweets that have the hashtag
    "has_next_page": boolean
}
```

#### Error Responses
* status_code_with_message
  * HTTP 400 if `limit < 1` or `page < 0`
    ```
    {
        "status": "error", 
        "error": "Limit must be greater than 0, Page must be greater than or equal to 0"
    }
    ```

### POST /api/v2/stream

Creates a new tweet in the tweet stream. The author will be the logged in user. The timestamp will be "Now". The post will have mentions and hashtags automatically extracted.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Json Request Body

```
{
    "text": "string", # Max length: 2,000 characters, UTF-8.
    "parent": "stream_post_id_string", # Optional
    "photo": "photo_id_string", # Optional
    "as_mod": boolean #Optional
}
```

* Text is required.  This will be the text of the tweet to be posted.
* parent is optional.  If Specified, it will make this post a reply to another StreamPost by the stream_post_id_string passed in.
* photo is optional.  If Specified, it will make this post link in the photo that has already been uploaded with the photo_id_string passed in.
* as_mod is optional. If it is set to true, and the current user has a priviliged role, the post will appear to be made by the moderator account.

#### Returns

```
{
    "status": "ok",
    "stream_post": StreamPost{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 400 if tweet with given parent ID is not found
    ```
    {
        "status": "error", 
        "error": "stream_post_id_string  is not a valid parent id" # stream_post_id_string will be replaced with the posted parent id
    } 
    ```
  * HTTP 403 if parent_id is included, the matching parent post is locked, and the user is not moderator or higher
    ```
    { "status": "error", "error": "Post is locked." }
    ```
* status_code_with_error_list - HTTP 400 with a list of problems
  ```
    { 
        "status": "error", 
        "errors": [
            "Text can't be blank",
            "Text is too long (maximum is 2000 characters)"
            "photo_id_string is not a valid photo id" # photo_id_string will be replaced with the posted photo id
        ]
    }
  ```
### GET /api/v2/tweet/:id

Gets a single tweet.

#### Returns

```
{
    "status": "ok",
    "stream_post": StreamPost{}
}
```

#### Error Responses
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
   ```
    { "status": "error", "error": "Post not found." }
   ```

### POST /api/v2/tweet/:id

Allows the user to edit the text or photo for this post.  Nothing else is modifyable. A user may only edit their own posts, unless they are an admin.

#### Requires

* logged in.
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "text": "string", # Max length: 2,000 characters, UTF-8.
    "photo": "photo_id_string" # Optional
}
```

Both text and photo are optional, however, at least one must be specified.  If one is not specified it will not be changed.

#### Returns

```
{
    "status": "ok",
    "stream_post": StreamPost{}
}
```

#### Error Responses
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    { 
        "status": "error", 
        "error": "Post not found."
    }
    ```
  * HTTP 403 if the user does not have permission to modify the tweet
    ```
    { 
        "status": "error", 
        "error": "You can not modify other users' posts" 
    }
    ```
  * HTTP 400 if neither text nor photo is included in the request
    ```
    { 
        "status": "error", 
        "error": "Update must modify either text or photo, or both." 
    }
    ```
  * HTTP 403 if the post is locked and the user is not moderator or higher
    ```
    { "status": "error", "error": "Post is locked." }
    ```
  * status_code_with_error_list - HTTP 400 with a list of problems
    ```
    { 
        "status": "error", 
        "errors": [
            "Text can't be blank",
            "Text is too long (maximum is 2000 characters)"
            "photo_id_string is not a valid photo id" # photo_id_string will be replaced with the posted photo id
        ]
    }
    ```

### DELETE /api/v2/tweet/:id

Allows the user to delete a post. A user may only delete their own posts, unless they are a moderator, tho, or admin user.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Returns

HTTP 204 No Content if deletion was successful

#### Error Responses
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    { 
        "status": "error", 
        "error": "Post not found."
    }
    ```
  * HTTP 403 if the user does not have permission to delete the tweet
    ```
    { 
        "status": "error", 
        "error": "You can not delete other users' posts" 
    }
    ```
  * HTTP 403 if the post is locked and the user is not moderator or higher
    ```
    { "status": "error", "error": "Post is locked." }
    ```

### POST /api/v2/tweet/:id/locked/:locked

Changes locked status for a stream post and its children. Locked stream posts cannot be modified in any way by users (moderators and above can still modify). Moderator login required. `:locked` should be either true or false.

### Requires

* logged in as Moderator, THO, or Admin
  * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "locked": boolean
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as Moderator, THO or Admin
* status_code_with_message
  * HTTP 404 if post with given ID is not found
   ```
    { "status": "error", "error": "Post not found." }
   ```

### POST /api/v2/tweet/:id/react/:type

React to a post. Type must come from the list of valid reaction words.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Returns

Summary of reactions that have been applied to the post.

```
{
    "status": "ok",
    "reactions": ReactionsSummary{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    {
        "status": "error",
        "error": "Post not found."
    }
    ```
  * HTTP 400 if `type` is not included
    ```
    {
        "status": "error",
        "error": "Reaction type must be included."
    }
    ```
  * HTTP 400 if `type` is not a valid reaction word
    ```
    {
        "status": "error",
        "error": "Invalid reaction: type" # type will be replaced with the posted type
    }
    ```
  * HTTP 403 if the post is locked and the user is not moderator or higher
    ```
    { "status": "error", "error": "Post is locked." }
    ```

### DELETE /api/v2/tweet/:id/react/:type

Remove reaction from a post. If `type` is not a valid reaction word, or if it has not been added to the post by the current user, this request will report success without making any modifications to the post.

#### Requires

* logged in.
  * Accepts: key query parameter

#### Returns

Summary of reactions that have been applied to the post.

```
{
    "status": "ok",
    "reactions": ReactionsSummary{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    {
        "status": "error",
        "error": "Post not found."
    }
    ```
  * HTTP 400 if `type` is not included
    ```
    {
        "status": "error",
        "error": "Reaction type must be included."
    }
    ```
  * HTTP 403 if the post is locked and the user is not moderator or higher
    ```
    { "status": "error", "error": "Post is locked." }
    ```

### GET /api/v2/tweet/:id/react

Get the list of reactions that have been applied to a post

#### Returns

All reactions that have been applied to the post.

```
{
    "status": "ok",
    "reactions": [ReactionDetails{}, ...]
}
```

#### Error Responses
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    { 
        "status": "error", 
        "error": "Post not found."
    }
    ```


## Photo Information

### Photo Specific types

#### PhotoMeta{}

```
{
    "id": "photo_id_string",
    "animated": boolean,
    "store_filename": "filename_string",
    "md5_hash": "md5_string",
    "content_type": "content_type_string",
    "uploader": "username_string",
    "upload_time": epoch,
    "sizes": [PhotoSize{}, ...]
}
```

### GET /api/v2/photo

Gets a list of images that have been uploaded to the server. This endpoint is currently admin-only, since adequate management tools do not currently exist.

#### Requires

* logged in as admin.
    * Accepts: key query parameter

#### Query parameters

* sort_by=string - Optional (Default: upload_time) - The field used for sorting the results.
* order=string - Optional (Default: asc) - Sort direction. Either asc or desc.
* limit=Integer - Optional (Default: 20) - Number of photos to return
* page=Integer - Optional (Default: 0) - The page of photos to retrieve, zero-indexed. Multiplied by `limit` to determine number of photos to skip.

#### Returns

A listing of photo metadata.

```
{
    "status": "ok",
    "total_count": integer,
    "page": integer,
    "photos": [ PhotoMeta{}, ...]
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in as an admin
* status_code_with_error_list - HTTP 400 with a list of any problems
  ```
  {
      "status": "error",
      "errors": [
          "Limit must be greater than 0",
          "Page must be greater than or equal to 0",
          "Invalid field name for sort_by",
          "Order must be either asc or desc"
      ]
  }
  ```

### POST /api/v2/photo

Upload a photo. Photo should be uploaded as form-data.

#### Requires
* logged in
    * Accepts: key query parameter

#### Post parameters
* file=photo_file - The form-data image file you are uploading

#### Returns

```
{
    "status": "ok",
    "photo": PhotoMeta{}
}
```

#### Error Resposnes

* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message - HTTP 400 with a message indicating what went wrong. Possible messages:
  * Must provide photo to upload.
  * File must be uploaded as form-data.
  * File was not an allowed image type - only jpg, gif, and png accepted.
  * Photo could not be opened - is it an image?
  * File exceeds maximum file size of 10MB.
  * Photo extension is jpg but could not be opened as jpeg.
  ```
  {
      "status": "error",
      "error": "error_message"
  }
  ```

### GET /api/v2/photo/:photo_id

#### Returns

A single photo's metadata

```
{
    "status": "ok",
    "photo": PhotoMeta{}
}
```

#### Error Resposnes
* status_code_with_message - HTTP 404 if the photo with the requested :photo_id is not found
  ```
    { "status": "error", "error": "Photo not found" }
  ```

### DELETE /api/v2/photo/:photo_id

Allows users or admins to delete a photo.

#### Requires
* logged in as the original photo uploader, or as admin.
    * Accepts: key query parameter

#### Returns

HTTP 204 No Content if deletion was successful

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message - HTTP 404 if the photo with the requested :photo_id is not found
  ```
    { "status": "error", "error": "Photo not found" }
  ```
* status_code_with_error_list - HTTP 400 with a list of any problems
  ```
  {
      "status": "error",
      "errors": [
          "You can not delete other users' photos"
      ]
  }
  ```

### GET /api/v2/photo/small_thumb/:photo_id

#### Returns

A small thumbnail image file suitable for embedding in a forum post or tweet.

#### Error Resposnes
* status_code_with_message - HTTP 404 if the photo with the requested :photo_id is not found
  ```
    { "status": "error", "error": "Photo not found" }
  ```

### GET /api/v2/photo/medium_thumb/:photo_id

#### Returns

A medium-sided image file suitable for a somewhat larger view of an image.

#### Error Resposnes
* status_code_with_message - HTTP 404 if the photo with the requested :photo_id is not found
  ```
    { "status": "error", "error": "Photo not found" }
  ```

### GET /api/v2/photo/full/:photo_id

#### Returns

The full-size original image file that was uploaded.

#### Error Resposnes
* status_code_with_message - HTTP 404 if the photo with the requested :photo_id is not found
  ```
    { "status": "error", "error": "Photo not found" }
  ```


## Hashtag Information

### GET /api/v2/hashtag/ac/:query

Get auto completion list for hashtags.  Query string length must be at least 3, # symbol is optional - it will be ignored and does not count toward query length.

#### Returns

```
{
    "values": ["hashtag_string", ...]
}
```

#### Error Responses
* status_code_with_message
  * HTTP 400 if query length is less than 3
    ```
    { 
        "status": "error", 
        "error": "Minimum length is 3"
    }
    ```

### GET /api/v2/hashtag/repopulate

Completely rebuilds the table of hashtags. This is extremely expensive. Only admins can use this endpoint.

#### Requires

* logged in as admin.
    * Accepts: key query parameter

#### Returns

```
{
    "values": ["hashtag_string", ...]
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in as an admin


## Search information

### GET /api/v2/search/all/:query

Perform a search against the database for results. Will search for users, seamails, stream posts, forum posts, and events.

#### Query params

* limit (optional) - The amount of objects per type returned, default 5
* page (optional) - The starting offset for objects being displayed (per type) returned, default 0

#### Returns

```
{
    "status": "ok",
    "query": {
        "text": "query_string" # This may have been modified from what was passed in. The value here is what was actually searched.
    },
    "users": {
        "matches": [ UserInfo{}, ... ],
        "count": integer, # Count of matches
        "more": boolean # True if there are more pages of results
    },
    "seamails": {
        "matches": [ SeamailThread{WITHOUT messages}, ... ],
        "count": integer, # Count of matches
        "more": boolean # True if there are more pages of results
    },
    "tweets": {
        "matches": [ StreamPost{}, ... ],
        "count": integer, # Count of matches
        "more": boolean # True if there are more pages of results
    },
    "forums": {
        "matches": [ ForumThreadMeta{}, ... ],
        "count": integer, # Count of matches
        "more": boolean # True if there are more pages of results
    },
    "events": {
        "matches": [ Event{}, ... ],
        "count": integer, # Count of matches
        "more": boolean # True if there are more pages of results
    }
}
```

#### Error Resposnes
* status_code_with_error_list - HTTP 400 with a list of any problems
  ```
    {
        "status": "error",
        "errors": [
            "Required parameter 'query' not set.",
            "Limit must be greater than 0.",
            "Page must be greater than or equal to 0."
        ]
    }
  ```

### GET /api/v2/search/users/:query

Perform a username search against the database for results.

#### Query params

* limit (optional) - The amount of objects per type returned, default 20
* page (optional) - The starting offset for objects being displayed (per type) returned, default 0

#### Returns

```
{
    "status": "ok",
    "query": {
        "text": "query_string" # This may have been modified from what was passed in. The value here is what was actually searched.
    },
    "users": {
        "matches": [ UserInfo{}, ... ],
        "count": integer, # Count of matches
        "more": boolean # True if there are more pages of results
    }
}
```

#### Error Resposnes
* status_code_with_error_list - HTTP 400 with a list of any problems
  ```
    {
        "status": "error",
        "errors": [
            "Required parameter 'query' not set.",
            "Limit must be greater than 0.",
            "Page must be greater than or equal to 0."
        ]
    }
  ```

### GET /api/v2/search/seamails/:query

Perform a seamail search against the database for results.

#### Query params

* limit (optional) - The amount of objects per type returned, default 5
* page (optional) - The starting offset for objects being displayed (per type) returned, default 0

#### Returns

```
{
    "status": "ok",
    "query": {
        "text": "query_string" # This may have been modified from what was passed in. The value here is what was actually searched.
    },
    "seamails": {
        "matches": [ SeamailThread{WITHOUT messages}, ... ],
        "count": integer, # Count of matches
        "more": boolean # True if there are more pages of results
    }
}
```

### GET /api/v2/search/tweets/:query

Perform a stream post search against the database for results.

#### Query params

* limit (optional) - The amount of objects per type returned, default 20
* page (optional) - The starting offset for objects being displayed (per type) returned, default 0

#### Returns

```
{
    "status": "ok",
    "query": {
        "text": "query_string" # This may have been modified from what was passed in. The value here is what was actually searched.
    },
    "tweets": {
        "matches": [ StreamPost{}, ... ],
        "count": integer, # Count of matches
        "more": boolean # True if there are more pages of results
    }
}
```

#### Error Resposnes
* status_code_with_error_list - HTTP 400 with a list of any problems
  ```
    {
        "status": "error",
        "errors": [
            "Required parameter 'query' not set.",
            "Limit must be greater than 0.",
            "Page must be greater than or equal to 0."
        ]
    }
  ```

### GET /api/v2/search/forums/:query

Perform a forum post search against the database for results.

#### Query params

* limit (optional) - The amount of objects per type returned, default 20
* page (optional) - The starting offset for objects being displayed (per type) returned, default 0

#### Returns

```
{
    "status": "ok",
    "query": {
        "text": "query_string" # This may have been modified from what was passed in. The value here is what was actually searched.
    },
    "forums": {
        "matches": [ ForumThreadMeta{}, ... ],
        "count": integer, # Count of matches
        "more": boolean # True if there are more pages of results
    }
}
```

#### Error Resposnes
* status_code_with_error_list - HTTP 400 with a list of any problems
  ```
    {
        "status": "error",
        "errors": [
            "Required parameter 'query' not set.",
            "Limit must be greater than 0.",
            "Page must be greater than or equal to 0."
        ]
    }
  ```

### GET /api/v2/search/events/:query

Perform an events search against the database for results.

#### Query params

* limit (optional) - The amount of objects per type returned, default 5
* page (optional) - The starting offset for objects being displayed (per type) returned, default 0

#### Returns

```
{
    "status": "ok",
    "query": {
        "text": "query_string" # This may have been modified from what was passed in. The value here is what was actually searched.
    },
    "events": {
        "matches": [ Event{}, ... ],
        "count": integer, # Count of matches
        "more": boolean # True if there are more pages of results
    },
}
```

#### Error Resposnes
* status_code_with_error_list - HTTP 400 with a list of any problems
  ```
    {
        "status": "error",
        "errors": [
            "Required parameter 'query' not set.",
            "Limit must be greater than 0.",
            "Page must be greater than or equal to 0."
        ]
    }
  ```


## User information

### User Specific types

#### UserAccount{}

This is used by user and admin endpoints. When used with admin endpionts, unnoticed_alerts is excluded.

```
{
    "username": "username_string",
    "role": "role_string",
    "email": "email_address",  # May be null
    "display_name": "displayname_string",
    "current_location": null, # Not currently implemented
    "last_login": epoch,
    "empty_password": boolean,
    "last_photo_updated": epoch,
    "room_number": "string", # May be null
    "real_name": "string", # May be null
    "pronouns": "string", # May be null
    "home_location": "string", # May be null
    "unnoticed_alerts": boolean # Excluded from admin endpoints
}
```

#### UserProfile{}

```
{
    "username": "username_string",
    "display_name": "displayname_string",
    "email": "email_address",  # May be null
    "current_location": null, # Not currently implemented
    "number_of_tweets": integer,
    "number_of_mentions": integer,
    "room_number": "integer", # String representation of an integer. May be null
    "real_name": "string", # May be null
    "pronouns": "string", # May be null
    "home_location": "string", # May be null
    "last_photo_updated": epoch,
    "starred": boolean, # Only returned if current user is logged in.
    "comment": "string" # Only returned if current user is logged in. May be null.
}
```

### POST /api/v2/user/new

Create a new user account. This will throw an error if it is called while logged in.

#### JSON Request Body

```
{
    "new_username": "username_string", # Username of the new user. If it is in use, an error will be returned. Max length: 40 characters, UTF-8.
    "new_password": "password_string", # Password of the new user. Min length: 6 characters, Max length: 100 characters, UTF-8.
    "display_name": "displayname_string", # Optional. The user's display name. Min length: 3 characters, Max length: 40 characters, UTF-8. Null is allowed.
    "registration_code": "string" # A code provided to the user which will allow them to register. Alphanumeric, case insensitive.
}
```

#### Returns

If the user is successfully created, a JSON object will be returned with the authentication 'key' of the logged in user (see /api/v2/user/auth) along with the new user's profile information.

```
{
    "status": "ok",
    "key": "string",
    "user": UserAccount{}
}
```

#### Error Resposnes
* status_code_with_parameter_errors
  * HTTP 400 if there were any errors with user account creation
  ```
  { 
    "status": "error", 
    "errors": {
        "general": [
            "Already logged in - log out before creating a new account."
        ],
        "new_username": [
            "Username must be three to forty characters long, and only include letters, numbers, underscore, dash, and ampersand.",
            "An account with this username already exists."
        ],
        "new_password": [
            "Your password must be at least six characters long.",
            "Your password cannot be more than 100 characters long."
        ],
        "registration_code": [
            "Invalid registration code."
        ],
        "display_name": [
            "If display name is entered, it must be three to forty characters long, and cannot include any of ~!@#$%^*()+=<>{}[]\\|;:/?"
        ]
    }
  }
  ```

### GET or POST /api/v2/user/auth

Log in user, returning a 'key' that can be used in each /api/v2 request that requires authentication. The key can be used instead of having a session cookie. If authenticating with GET, use Query Parameters. If authenticating with POST, use JSON Request Body.

#### Query Parameters

* username=username_string
* password=password_string

#### JSON Request Body

```
{
    "username": "username_string",
    "password": "password_string"
}
```

#### Returns

```
{
    "status": "ok",
    "username": "username_string",
    "key": "string"
}
```

#### Error Resposnes
* status_code_with_message
  * HTTP 401 with an error message. Possible messages:
    * Invalid username or password.
    * User account has been disabled.
    ```
    {
        "status": "error", 
        "error": "error_message"
    }
    ```

### GET or POST /api/v2/user/logout

Removes session data for the user. If your application uses 'key' for authentication, calling logout will have no effect - keys are not invalidated by this endpoint. This may change in the future. If your app uses key instead of session cookie, all you need to do for a logout is clean up any cached user data, and forget your key.

#### Returns

```
{
    "status": "ok"
}
```

### GET /api/v2/user/whoami or /api/v2/user/profile

Returns the logged in user's account information.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Returns

```
{
    "stauts": "ok",
    "user": UserAccount{},
    "need_password_change": boolean # If this is true, the user should be prompted to change their password.
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in

### POST /api/v2/user/profile

Updates the user's profile. All fields are optional - anything left out of the request will not be updated. To clear a field, send null or an empty string.

#### Requires
* logged in
    * Accepts: key query parameter

#### JSON Request Body

```
{
	"display_name": "display_name_string", # Min length: 3 characters, Max length: 40 characters, UTF-8. Null is allowed.
	"email": "email_string",
	"home_location": "string", # Max length: 100 chatarcters, UTF-8.
	"real_name": "string", # Max length: 100 chatarcters, UTF-8.
	"pronouns": "string", # Max length: 100 chatarcters, UTF-8.
	"room_number": Integer # If not null/empty, Min length: 4 characters, Max length: 5 characters, UTF-8. Also accepts string representation of an integer.
}
```

#### Returns

```
{
    "status": "ok",
    "user": UserAccount{}
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_parameter_errors
  * HTTP 400 if there were any errors with profile data
  ```
  { 
    "status": "error", 
    "errors": {
        "display_name": [
            "If display name is entered, it must be three to forty characters long, and cannot include any of ~!@#$%^*()+=<>{}[]\\|;:/?"
        ],
        "email": [
            "E-mail address is not valid."
        ],
        "room_number": [
            "Room number must be blank or an integer."
        ]
    }
  }
  ```

### POST /api/v2/user/change_password

Allows the user to change their password.

#### Requires
* logged in
    * Accepts: key query parameter

#### JSON Request Body

```
{
	"current_password": "password_string",
	"new_password": "password_string"
}
```

#### Returns

```
{
    "status": "ok",
    "key": "string" # A new key based on the updated hashed password
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_parameter_errors
  * HTTP 400 if there were any errors with updating the password
  ```
  { 
    "status": "error", 
    "errors": {
        "current_password": [
            "Current password is incorrect."
        ],
        "new_password": [
            "New password must be at least six characters long."
        ]
    }
  }
  ```

### POST /api/v2/user/reset_password

Allows a user to use their registration code to reset their password.

#### JSON Request Body

```
{
    "username": "username_string",
	"registration_code": "string",
	"new_password": "password_string"
}
```

#### Returns

```
{
    "status": "ok",
    "message": "Your password has been changed."
}
```

#### Error Resposnes
* status_code_with_parameter_errors
  * HTTP 400 if there were any errors
  ```
  { 
    "status": "error", 
    "errors": {
        "username": [
            "Username and registration code combination not found."
        ],
        "new_password": [
            "New password must be at least six characters long, and cannot be more than 100 characters long."
        ]
    }
  }
  ```

### GET /api/v2/user/mentions

Gets the count of the user's unnoticed mentions. This count is increased by 1 for a user any time another user includes @username in a tweet or forum post.

#### Requires
* logged in
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "mentions": Integer
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in

### DELETE /api/v2/user/mentions # DISABLED

This is no longer supported. Instead, use the alerts endpoint `POST /api/v2/alerts/last_viewed`

#### Requires
* logged in
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "mentions": Integer
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in

### GET /api/v2/user/ac/:query

Get auto completion list for usernames. :query string must be at least 1 character long. If the @ symbol is included, it will be ignored and not counted towards the length. It will return a maximum of 10 results.

#### Returns

```
{
    "status": "ok",
    "users": [
        UserInfo{}, ...
    ]
}
```

#### Error Resposnes
* status_code_with_message
  * HTTP 400 if :query is too short
    ```
    {
        "status": "error", 
        "error": "Minimum length is 1"
    }
    ```

### GET /api/v2/user/profile/:username

Get a user's public profile information, including the user's 10 most recent tweets.

#### Returns

```
{
    "status": "ok",
    "user": UserProfile{},
    "recent_tweets": [ StreamPost{}, ... ],
    "starred": boolean, # Only present if current user is logged in
    "comment": string or null # Only present if current user is logged in
}
```

#### Error Resposnes
* status_code_with_message - HTTP 404 if the user is not found
  ```
    { "status": "error", "error": "User not found." }
  ```

### POST /api/v2/user/profile/:username/personal_comment

Allows the current user to save a private comment about another user. Whenever the current user retrieves the other user's profile, this comment will be included.

#### Requires
* logged in
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "comment": "string" # Max length: 5,000 characters, UTF-8.
}
```

#### Returns
```
{
    "status": "ok",
    "user": UserProfile{}
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message - HTTP 404 if the user is not found
  ```
    { "status": "error", "error": "User not found." }
  ```
* status_code_with_message - HTTP 400 if `comment` is too long
  ```
    { "status": "error", "error": "Comment is too long (maximum is 5000 characters)" }
  ```

### POST /api/v2/user/profile/:username/star

Toggles the starred status of the user - used to follow and unfollow a particular user.

#### Requires
* logged in
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "starred": boolean
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message - HTTP 404 if the user is not found
  ```
    { "status": "error", "error": "User not found." }
  ```

### GET /api/v2/user/starred

Gets an abbreviated listing of users starred by the current user, along with any personal comments.

#### Requires
* logged in
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "users": [
        UserInfo{
            "comment": "string" # The comment field is appended to the UserInfo{} type
        }, ...
    ]
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in

### GET /api/v2/user/photo/:username

Get a cropped thumbnail of a user's profile photo.

#### Query Parameters

* full=boolean - Optional. If true, the query will return uncropped full size image.

#### Returns

An image file.

#### Error Resposnes
* status_code_with_message - HTTP 404 if the user is not found
  ```
    { "status": "error", "error": "User not found." }
  ```

### POST /api/v2/user/photo

Replace the user's profile photo.

#### Requires
* logged in
    * Accepts: key query parameter

#### Post parameters
* file=photo_file - The form-data image file you are uploading

#### Returns

```
{
    "status": "ok",
    "md5_hash": "string"
}
```

#### Error Resposnes

* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message - HTTP 400 with a message indicating what went wrong. Possible messages:
  * Must provide photo to upload.
  * File must be uploaded as form-data.
  * File was not an allowed image type - only jpg, gif, and png accepted.
  * Photo could not be opened - is it an image?
  * File exceeds maximum file size of 10MB.
  * Photo extension is jpg but could not be opened as jpeg.
  ```
  {
      "status": "error",
      "error": "error_message"
  }
  ```

### DELETE /api/v2/user/photo

Reset the user's profile photo to their default identicon image.

#### Requires
* logged in
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "md5_hash": "string"
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in

### POST /api/v2/user/schedule

Upload an .ics schedule. Schedule should be uploaded as form-data. Any event in the .ics file that matches an event in the database will be marked as Followed for the user.

#### Requires
* logged in
    * Accepts: key query parameter

#### Query parameters
* schedule=file - The from-data schedule file.

#### Returns

```
{ "status": "ok" }
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message - HTTP 400 if the uploaded schedule could not be parsed
  ```
    { 
        "status": "error", 
        "error": "Unable to parse schedule: errorMessage" # Error message will be replaced with a hopefully helpful message describing what went wrong
    }
  ```


## Forum information

Get/post new threads and posts to those threads

### Forum Specific types

#### ForumThreadMeta

```
{
    "id": "forum_id_string",
    "subject": "subject_string",
    "sticky": boolean,
    "locked": boolean,
    "last_post_author": {
        UserInfo{}
    }
    "posts": Integer, # A count of posts in the thread
    "timestamp": epoch, # Timestamp of the last post in the thread
    "last_post_page": Integer, # Will be 0 if user is not logged in
    "count": Integer, # Number of posts since user's last view, only included if user is logged in
    "new_posts": boolean # Only included if user is logged in
}
```

#### ForumThread

```
{
    "id": "forum_id_string"
    "subject": "subject_string",
    "sticky": boolean,
    "locked": boolean,
    "next_page": null|Integer, # Only included if paging was requested through query parameters
    "prev_page": null|Integer, # Only included if paging was requested through query parameters
    "page_count": Integer, # Only included if paging was requested through query parameters
    "post_count": Integer,
    "posts": [ ForumPost{}, ... ],
    "latest_read": epoch, # Timestamp of when the user last viewed the thread, only included if user is logged in
}
```

#### ForumPost

```
{
    "id": "post_id_string",
    "forum_id": "forum_id_string",
    "author": UserInfo{},
    "thread_locked": boolean,
    "text": "string",
    "timestamp": epoch, # Timestamp of when the post was made
    "photos": [ PhotoDetails{}, ... ],
    "new": boolean # Only included if the user is logged in
}
```

### GET /api/v2/forums/

Returns a page of forum threads.

#### Query parameters

* page=integer - Optional, default 0 - Pages are 0-indexed
* limit=integer - Optional, default 20 - Number of threads per page

#### Returns

```
{
    "status": "ok",
    "forum_threads": [ ForumThreadMeta{}, ... ],
    "next_page": Integer, # Will be null if there is no next page
    "prev_page": Integer, # Will be null if there is no previous page
    "thread_count": Integer,
    "page_count": Integer
}
```

#### Error Resposnes
* status_code_with_error_list - HTTP 400 with a list of problems
```
{ 
    "status": "error", 
    "errors": [
        "Page size must be greater than zero.",
        "Page must be greater than or equal to zero."
    ]
}
```

### POST /api/v2/forums

Creates a forum thread and its first post.

### Requires

* logged in.
  * Accepts: key query parameter

#### JSON Request Body

```
{
    "subject": "string", # Max length: 200 characters, UTF-8.
    "text": "string", # Max length: 10,000 characters, UTF-8.
    "photos": ["photo_id_string", ...], # Optional
    "as_mod": boolean # Optional
}
```
* photos is optional.  If specified, it will make this post link in the photos that have already been uploaded with the photo_id_strings passed in.
* as_mod is optional. If it is set to true, and the current user has a priviliged role, the post will appear to be made by the moderator account.

#### Returns

```
{
    "status": "ok",
    "forum_thread": ForumThread{}
}
```

#### Error Resposnes
* status_code_with_error_list - HTTP 400 with a list of problems
```
{
    "status": "error",
    "errors": [
        "Subject can't be blank",
        "Subject is too long (maximum is 200 characters)",
        "Text can't be blank",
        "Text is too long (maximum is 10000 characters)",
        "photo_id_string is not a valid photo id" # photo_id_string will be replaced with the invalid photo id
    ]
}
```

### GET /api/v2/forums/:id

Returns a forum thread and its posts.

#### Query parameters

* page=integer - Optional - 0-indexed. If not present, will respond with all posts in the thread.
* limit=integer - Optional, default 20 - When used in conjunction with page parameter, will determine how many posts are shown per page

#### Returns
  
```
{
    "status": "ok",
    "forum_thread": ForumThread{}
}
```

#### Error Resposnes
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```

### POST /api/v2/forums/:id

Creates a new post in the thread.

### Requires
* logged in.
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "text": "string", # Max length: 10,000 characters, UTF-8.
    "photos": ["photo_id_string", ...], # Optional
    "as_mod": boolean
}
```

* photos is optional. If specified, it will make this post link in the photos that have already been uploaded with the photo_id_strings passed in.
* as_mod is optional. If it is set to true, and the current user has a priviliged role, the post will appear to be made by the moderator account.

#### Returns

```
{
    "status": "ok",
    "forum_post": ForumPost{}
}
```

#### Error Resposnes
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
    ```
    { "status": "error", "error": "Forum thread not found." }
    ```
  * HTTP 403 if the forum thread is locked and the user is not moderator or higher
    ```
    { "status": "error", "error": "Forum thread is locked." }
    ```
* status_code_with_error_list - HTTP 400 with a list of problems
```
{
    "status": "error",
    "errors": [
        "Text can't be blank",
        "Text is too long (maximum is 10000 characters)",
        "photo_id_string is not a valid photo id" # photo_id_string will be replaced with the invalid photo id
    ]
}
```

### DELETE /api/v2/forum/:id

Deletes an entire forum thread. Moderator or higher required.

### Requires

* logged in as Moderator, THO or Admin
  * Accepts: key query parameter

#### Returns

```
{
    "status": "ok"
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as Moderator, THO or Admin
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```

### POST /api/v2/forum/:id/sticky/:sticky

Changes sticky status for a forum thread. Sticky threads will be sorted before other threads. THO or Admin login required. `:sticky` should be either true or false.

### Requires

* logged in as THO or Admin
  * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "sticky": boolean
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as THO or Admin
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```

### POST /api/v2/forum/:id/locked/:locked

Changes locked status for a forum thread. Locked threads cannot be modified in any way by users (moderators and above can still modify). Moderator login required. `:locked` should be either true or false.

### Requires

* logged in as Moderator, THO, or Admin
  * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "locked": boolean
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as Moderator, THO or Admin
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```

### GET /api/v2/forums/:id/:post_id

Returns a single post from a forum thread. Useful for getting the current state of a post before performing an edit.

#### Returns
  
```
{
    "status": "ok",
    "forum_post": ForumPost{}
}
```

#### Error Resposnes
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```
   * HTTP 404 if post with given Post ID is not found
   ```
    { "status": "error", "error": "Post not found." }
   ```

### POST /api/v2/forums/:id/:post_id

Edits a post in the thread.

### Requires
* logged in as either the post author or admin
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "text": "string", # Max length: 10,000 characters, UTF-8.
    "photos": ["photo_id_string", ...]
}
```

#### Returns

```
{
    "status": "ok",
    "forum_post": ForumPost{}
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```
   * HTTP 404 if post with given Post ID is not found
   ```
    { "status": "error", "error": "Post not found." }
   ```
   * HTTP 401 if the current user is not the post author or an admin
   ```
    { "status": "error", "error": "You can not edit other users' posts." }
   ```
   * HTTP 403 if the forum thread is locked and the user is not moderator or higher
   ```
    { "status": "error", "error": "Forum thread is locked." }
   ```
* status_code_with_error_list - HTTP 400 with a list of problems
```
{
    "status": "error",
    "errors": [
        "Text can't be blank",
        "Text is too long (maximum is 10000 characters)",
        "photo_id_string is not a valid photo id" # photo_id_string will be replaced with the invalid photo id
    ]
}
```

### DELETE /api/v2/forums/:id/:post_id

Deletes a post from a thread. If the post was the only post in the thread, the thread will also be deleted.

### Requires
* logged in as either the post author, or as moderator, tho, or admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "thread_deleted": boolean # Will be true if the thread was also deleted
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```
   * HTTP 404 if post with given Post ID is not found
   ```
    { "status": "error", "error": "Post not found." }
   ```
   * HTTP 401 if the current user is not the post author or an admin
   ```
    { "status": "error", "error": "You can not delete other users' posts." }
   ```
   * HTTP 403 if the forum thread is locked and the user is not moderator or higher
   ```
    { "status": "error", "error": "Forum thread is locked." }
   ```

### POST /api/v2/forums/:id/:post_id/react/:type

React to a post. Type must come from the list of valid reaction words.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Returns

Summary of reactions that have been applied to the post.

```
{
    "status": "ok",
    "reactions": ReactionsSummary{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```
   * HTTP 404 if post with given Post ID is not found
   ```
    { "status": "error", "error": "Post not found." }
   ```
  * HTTP 400 if `type` is not included
    ```
    { "status": "error", "error": "Reaction type must be included." }
    ```
  * HTTP 400 if `type` is not a valid reaction word
    ```
    {
        "status": "error",
        "error": "Invalid reaction: type" # type will be replaced with the posted type
    }
    ```
  * HTTP 403 if the forum thread is locked and the user is not moderator or higher
    ```
    { "status": "error", "error": "Forum thread is locked." }
    ```

### DELETE /api/v2/forums/:id/:post_id/react/:type

Remove reaction from a forum post. If `type` is not a valid reaction word, or if it has not been added to the forum post by the current user, this request will report success without making any modifications to the forum post.

#### Requires

* logged in.
  * Accepts: key query parameter

#### Returns

Summary of reactions that have been applied to the forum post.

```
{
    "status": "ok",
    "reactions": ReactionsSummary{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```
   * HTTP 404 if post with given Post ID is not found
   ```
    { "status": "error", "error": "Post not found." }
   ```
  * HTTP 400 if `type` is not included
    ```
    { "status": "error", "error": "Reaction type must be included." }
    ```
  * HTTP 403 if the forum thread is locked and the user is not moderator or higher
    ```
    { "status": "error", "error": "Forum thread is locked." }
    ```

### GET /api/v2/forums/:id/:post_id/react

Get the list of reactions that have been applied to a forum post

#### Returns

All reactions that have been applied to the forum post.

```
{
    "status": "ok",
    "reactions": [ReactionDetails{}, ...]
}
```

#### Error Responses
* status_code_with_message
  * HTTP 404 if thread with given ID is not found
   ```
    { "status": "error", "error": "Forum thread not found." }
   ```
   * HTTP 404 if post with given Post ID is not found
   ```
    { "status": "error", "error": "Post not found." }
   ```


## Event Information

View and manage the schedule of events.

### Event specific types

#### Event

```
{
    "id": "id_string",
    "title": "title_string",
    "location": "location_string",
    "start_time": epoch,
    "end_time": epoch or null, # This will be null if the event has no end time.
    "official": boolean # True if the event is an official event. False if the event is a shadow event.
    "description": "string", # Only present if the event has a description. Uses the same markup as post text.
    "following": boolean
}
```

### GET /api/v2/event

Returns a list of all events. No filtering or sorting - just a straight events dump.

#### Returns

```
{
    "status": "ok",
    "total_count": Integer,
    "events": [Event{}, ...]
}
```

### GET /api/v2/event/day/:epoch

Gets a list of all events with a start time on the same day as :epoch.

#### Returns

```
{
    "status": "ok",
    "events": [Event{}, ...],
    "today": epoch,
    "prev_day": epoch,
    "next_day": epoch
}
```

### GET /api/v2/event/mine/:epoch

Gets a list of favorited events with a start time on the same day as :epoch.

#### Returns

```
{
    "status": "ok",
    "events": [Event{}, ...],
    "today": epoch,
    "prev_day": epoch,
    "next_day": epoch
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in

### GET /api/v2/event/:id

Get details of an event.

#### Returns

```
{
    "status": "ok",
    "event": Event{}
}
```

#### Error Responses
* status_code_with_message
  * HTTP 404 if event with given ID is not found
   ```
    { "status": "error", "error": "Event not found." }
   ```

### GET /api/v2/event/:id/ical

Get details of an event as an ical file.

#### Returns

File download: event_name.ics

#### Error Responses
* status_code_with_message
  * HTTP 404 if event with given ID is not found
   ```
    { "status": "error", "error": "Event not found." }
   ```

### DELETE /api/v2/event/:id

Remove an event. Only admins may remove events.

#### Requires

* logged in as an admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok"
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in as an admin
* status_code_with_message
  * HTTP 404 if event with given ID is not found
   ```
    { "status": "error", "error": "Event not found." }
   ```

### POST /api/v2/event/:id

Allows an admin to edit the title, description, location, start time, and end time of an event.

#### Requires

* logged in as an admin.
    * Accepts: key query parameter

#### Json Request Body

```
{
    "title": "string",
    "description": "string",
    "location": "string",
    "start_time": epoch,
    "end_time": epoch
}
```    

#### Returns

```
{
    "status": "ok",
    "event": Event{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in as an admin
* status_code_with_message
  * HTTP 404 if event with given ID is not found
   ```
    { "status": "error", "error": "Event not found." }
   ```

### POST /api/v2/event/:id/favorite

Allows the user to favorite an event.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "event": Event{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if event with given ID is not found
   ```
    { "status": "error", "error": "Event not found." }
   ```

### DELETE /api/v2/event/:id/favorite

Allows the user to remove their favorite from an event.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "event": Event{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if event with given ID is not found
   ```
    { "status": "error", "error": "Event not found." }
   ```


## Text Information

### GET /api/v2/text/:filename

Returns text for display to the user. Valid filenames can be found in /public/text - do not include the .json extension. For example: `/api/v2/text/codeofconduct`

This enpoint will return the full contents of the file as json. Currently, there is no validation on the format of the file, but this may change.

For files to be displayed in the ember web front-end, there is a recommended format: Each section can have an optional header, and an optional array of paragraphs. Each paragraph can include text and/or a list. If both are present, when presenting to a user, the intent is to display text first, then the list. A quick sample of this format is included in the Returns section below.

#### Returns

```
{
    "filename_string": { # for example, "codeofconduct"
        "sections": [
            {
                "header": "string",
                "paragraphs": [
                    {
                        "text": "string",
                        "list": ["string", ...]
                    }, ...
                ]
            }, ...
        ]
    }
}
```

#### Error Resposnes
* status_code_with_message
  * HTTP 404 if the file is not found
    ```
    { "status": "error", "error": "File not found." }
    ```

### GET /api/v2/time

Returns the server time.

#### Returns

```
{
    "status": "ok",
    "epoch": epoch,
    "time": "time_string", # Uses this ruby format: '%B %d, %l:%M %P %Z'
    "offset": Integer # Server timezone offset
}
```

### GET /api/v2/reactions

Returns a list of valid reaction words.

#### Returns

```
{
    "status": "ok",
    "reactions": ["reaction_word", ...]
}
```

### GET /api/v2/announcements

Returns currently active announcements.

#### Returns

```
{
    "status": "ok",
    "announcements": [Announcement{}, ...]
}
```


## Alerts Information

Alerts endpoints behave differently depending on whether or not the user is logged in. 

If the user is not logged in, the user will only get alerts for announcements. Additionally, the last time the user viewed alerts (accessed the `/api/v2/alerts` endpoint) will be stored in a cookie. That cookie's value will be used for determining which announcements are considered new when accessing the `check` endpoint. If your client does not allow cookies, you should store the `last_checked_time` value returned by the `/api/v2/alerts` endpoint and pass it in to future calls of `alerts` and `check`. If the `last_checked_time` is not submitted through a parameter or the cookie, the server will use the beginning of time when computing which announcements are new - that is, the unauthenticated user will be told ALL announcements are new.

If the user is logged in, the last viewed time is stored in the user's account, and there is no need to pass a value or a cookie to the alerts endpoints.

### GET /api/v2/alerts

Returns the data for the user's current alerts, along with all active announcements. If the `no_reset` parameter is not set, the current time will be stored as the user's `last_checked_time`.

#### Query parameters

* last_checked_time=epoch - Optional, default: beginning of time. Ignored if user is logged in or if cookie with this value is present.
* no_reset=true - Optional. If this parameter is present, the last_checked_time will not be updated for the user, or in the cookie if unauthenticated.

#### Returns

```
{
    "status": "ok",
    "announcements": [Announcement{}, ...],
    "tweet_mentions": [StreamPost{}, ...], # Will be an empty array if user is unauthenticated.
    "forum_mentions": [ForumThreadMeta{}, ...], # Will be an empty array if user is unauthenticated.
    "unread_seamail": [SeamailThread{ WITHOUT messages }, ...], # Will be an empty array if user is unauthenticated.
    "upcoming_events": [Event{}, ...], # Will be an empty array if user is unauthenticated.
    "last_checked_time": epoch, # Timestamp of when the user last checked their alerts. Will match query_time unless no_reset is set.
    "query_time": epoch # Timestamp of when the query was made
}
```

### GET /api/v2/alerts/check

Returns a count of new alerts since the user last accessed the alerts endpoint (see notes above about how `last_checked_time` is handled for authenticated vs unauthenticated users).

#### Query parameters

* last_checked_time=epoch - Optional, default: beginning of time. Ignored if user is logged in or if cookie with this value is present.

#### Returns

```
{
    "status": "ok",
    "alerts": {
        "unnoticed_announcements": Integer,
        "unnoticed_alerts": boolean, # True if the user has any unnoticed alerts. Only present if user is logged in.
        "seamail_unread_count": Integer, # Only present if user is logged in.
        "unnoticed_mentions": Integer, # Only present if user is logged in.
        "unnoticed_upcoming_events": Integer # Only present if user is logged in.
    }
}
```

### POST /api/v2/alerts/last_checked

Allows a user to set their last_checked_time time to a specific value.

#### Requires
* logged in
    * Accepts: key query parameter

#### JSON Request Body

```
{
	"last_checked_time": epoch
}
```

#### Returns

```
{
    "status": "ok",
    "last_checked_time": epoch
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in
* HTTP 400 if last_checked_time could not be parsed
    ```
    { 
        "status": "error", 
        "error": "Unable to parse timestamp." 
    }
    ```
* HTTP 400 if last_checked_time is in the future
    ```
    { 
        "status": "error", 
        "error": "Timestamp must be in the past." 
    }
    ```


## Admin Information

### Admin Specific Types

#### UserAdmin{}

```
{
    "username": "username_string",
    "role": "role_string",
    "email": "email_address",  # May be null
    "display_name": "displayname_string",
    "current_location": null, # Not currently implemented
    "last_login": epoch,
    "empty_password": boolean,
    "last_photo_updated": epoch,
    "room_number": "integer", # String representation of an integer. May be null
    "real_name": "string", # May be null
    "pronouns": "string", # May be null
    "home_location": "string" # May be null
    "mute_reason": "string" # May be null, required if user role is muted
    "ban_reason": "string" # May be null, required if user role is banned
}
```

#### AnnouncementAdmin{}

```
{
    "id": "id_string",
    "author": "username_string",
    "text": "formatted_string",
    "timestamp": epoch, # Timestamp of when the announcement was created
    "valid_until": epoch # Timestamp of when the announcement will disappear
}
```

#### Section{}

```
{
    "name": "string",
    "enabled": boolean
}
```

### GET /api/v2/admin/users

Returns a list of all users. No paging. Most clients shouldn't implement this.

#### Requires
* logged in as moderator, tho, or admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "users": [UserAdmin{}, ...]
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in as moderator, tho, or admin

### GET /api/v2/admin/users/:query

Returns a list of users matching `:query`. Searches username and display name.

#### Requires
* logged in as moderator, tho, or admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "search_text": "string", # Will usually match :query, may be slightly transformed
    "users": [UserAdmin{}, ...]
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in as moderator, tho, or admin

### GET /api/v2/admin/user/:username/profile

#### Requires
* logged in as moderator, tho, or admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "user": UserAdmin{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in as moderator, tho, or admin
* status_code_with_message - HTTP 404 if the user is not found
  ```
    { "status": "error", "error": "User not found." }
  ```

### POST /api/v2/admin/user/:username

Allows a priviliged user to edit a user's public profile fields. All fields in the JSON request body are optional - only present fields will be updated.

#### Requires
* logged in as moderator, tho, or admin.
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "role": "role_string", # Allows priviliged users to change the role of other users. Users cannot change their own roles.
    "status": "status_string",
	"display_name": "display_name_string", # Min length: 3 characters, Max length: 48 characters, UTF-8. 
	"email": "email_string",
	"home_location": "string", # Max length: 100 chatarcters, UTF-8.
	"real_name": "string", # Max length: 100 chatarcters, UTF-8.
	"pronouns": "string", # Max length: 100 chatarcters, UTF-8.
	"room_number": Integer # If not null/empty, Min length: 4 characters, Max length: 5 characters, UTF-8. Also accepts string representation of an integer.
    "mute_reason": "string" # Required if user role is "muted"
    "ban_reason": "string" # Required if user role is "banned"
}
```

#### Returns

```
{
    "status": "ok",
    "user": UserAdmin{}
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as moderator, tho, or admin
* status_code_with_message - HTTP 404 if the user is not found
  ```
    { "status": "error", "error": "User not found." }
  ```
* status_code_with_parameter_errors
  * HTTP 400 if there were any errors with profile data
  ```
  { 
    "status": "error", 
    "errors": {
        "display_name": [
            "If display name is entered, it must be three to forty characters long, and cannot include any of ~!@#$%^*()+=<>{}[]\\|;:/?"
        ],
        "email": [
            "E-mail address is not valid."
        ],
        "room_number": [
            "Room number must be blank or an integer."
        ],
        "role": [
            "You cannot change your own role.",
            "Invalid role. Must be one of: [role_strings].", # [role_strings] will be replaced with a list of valid roles
            "Only Admin and THO can ban or unban users.",
            "Only Admin and THO can change priviliged roles.",
            "Only Admin can grant or revoke the admin role."
        ],
        "mute_reason": [
            "When user is muted, mute reason is required."
        ],
        "ban_reason": [
            "When user is banned, ban reason is required."
        ]
    }
  }
  ```

### POST /api/v2/admin/user/:username/activate DISABLED

Sets a user's status to ACTIVE. Currently disabled.

#### Requires
* logged in as admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "user": UserAdmin{}
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as an admin
* status_code_with_message - HTTP 404 if the user is not found
  ```
    { "status": "error", "error": "User not found." }
  ```

### POST /api/v2/admin/user/:username/reset_password

Resets a user's password to the default password.

#### Requires
* logged in as tho or admin.
    * Accepts: key query parameter

#### Returns

```
{
    "stauts": "ok"
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as tho or admin
* status_code_with_message - HTTP 404 if the user is not found
  ```
    { "status": "error", "error": "User not found." }
  ```

### POST /api/v2/admin/user/:username/reset_photo

Reset the user's profile photo to their default identicon image.

#### Requires
* logged in as moderator, tho, or admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "md5_hash": "md5_string"
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as moderator, tho, or admin
* status_code_with_message - HTTP 404 if the user is not found
  ```
    { "status": "error", "error": "User not found." }
  ```

### GET /api/v2/admin/user/:username/regcode

Returns the user's registration code.

#### Requires
* logged in as tho or admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "registration_code": "string"
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as tho or admin
* status_code_with_message - HTTP 404 if the user is not found
  ```
    { "status": "error", "error": "User not found." }
  ```

### GET /api/v2/admin/announcements

Returns a list of all announcements, including expired announcements.

#### Requires
* logged in as tho or admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "announcements": [AnnouncementAdmin{}, ...]
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as tho or admin

### POST /api/v2/admin/announcements

Creates a new announcement. Announcement will be displayed to users until the timestamp `valid_until`.

#### Requires
* logged in as tho or admin.
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "text": "string",
    "valid_until": epoch
}
```

#### Returns

```
{
    "status": "ok",
    "announcement": AnnouncementAdmin{}
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as tho or admin
* status_code_with_error_list - HTTP 400 with a list of any problems
  ```
    {
        "status": "error",
        "errors": [
            "Text is required.",
            "Unable to parse valid until.",
            "Valid until must be in the future."
        ]
    }
  ```

### GET /api/v2/admin/announcements/:id

Get a single announcement by its id.

#### Requires
* logged in as tho or admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok",
    "announcement": AnnouncementAdmin{}
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as tho or admin
* status_code_with_message - HTTP 404 if the announcement is not found
  ```
    { "status": "error", "error": "Announcement not found." }
  ```

### POST /api/v2/admin/announcements/:id

Update an announcement. All fields are required. If no changes for a field, just send the existing data.

#### Requires
* logged in as tho or admin.
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "text": "string",
    "valid_until": epoch
}
```

#### Returns

```
{
    "status": "ok",
    "announcement": AnnouncementAdmin{}
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as tho or admin
* status_code_with_message - HTTP 404 if the announcement is not found
  ```
    { "status": "error", "error": "Announcement not found." }
  ```
* status_code_with_error_list - HTTP 400 with a list of any problems
  ```
    {
        "status": "error",
        "errors": [
            "Text is required.",
            "Unable to parse valid until.",
            "Valid until must be in the future."
        ]
    }
  ```

### DELETE /api/v2/admin/announcements/:id

Delete an announcement.

#### Requires
* logged in as tho or admin.
    * Accepts: key query parameter

#### Returns

```
{
    "status": "ok"
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as tho or admin
* status_code_with_message - HTTP 404 if the announcement is not found
  ```
    { "status": "error", "error": "Announcement not found." }
  ```

### POST /api/v2/admin/schedule

Upload an .ics schedule. Schedule should be uploaded as form-data. Creates new events, and updates existing events with matching IDs.

#### Requires
* logged in as admin.
    * Accepts: key query parameter

#### Query parameters
* schedule=file - The from-data schedule file.

#### Returns

```
{ "status": "ok" }
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as an admin
* status_code_with_message - HTTP 400 if the uploaded schedule could not be parsed
  ```
    { 
        "status": "error", 
        "error": "Unable to parse schedule: errorMessage" # Error message will be replaced with a hopefully helpful message describing what went wrong
    }
  ```

### GET /api/v2/admin/sections

Gets the list of site sections and their current status. Note that this admin endpoint has no access restrictions.

#### Returns

```
{
    "status": "ok",
    "sections": [ Section{}, ... ]
}
```

### POST /api/v2/admin/sections/:name

Change the status of a section.

#### Requires
* logged in as tho or admin.
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "enabled": boolean
}
```

#### Returns

```
{
    "status": "ok",
    "section": Section{}
}
```

#### Error Resposnes
* status_code_only - HTTP 401 if user is not logged in as tho or admin
* status_code_with_message - HTTP 404 if the section is not found.
  ```
    { "status": "error", "error": "Section not found." }
  ```
