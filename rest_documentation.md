# Rest Documentation

This documentation is for the rest endpoints under /api/v2

## Global Query Parameters
* app=plain - If this is included in the query parameters, no HTML text formatting will be applied to marked_up_text. Returned text will be plain text instead. This is useful in any endpoint that returns stream post text, forum post text, or seamail text.

## Parameter Type Definitions

* boolean - (true, false, 1, 0, yes, no)
* datetime string - ISO 8601 date/time string, or milliseconds since the unix epoch as a string
* ISO_8601_DATETIME - ISO 8601 date/time string
* epoch - milliseconds since the unix epoch as an integer
* id_string - a string for the id
* username_string - user's username.  All lowercase word characters plus '-' and '&', at least 3 characters
* displayname_string - user's display name. All word characters plus '.', '&', '-', and space, at least 3 characters, max 40 characters.

## Output Type Definitions

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
* likes_summary - null (if no likes), or an array
  * First element will be "You" if current_user likes the post: ["You", ...]
  * If fewer than MAX_LIST_LIKES, array will include usernames: ["username_string", ...] OR ["You", "username_string", ...] 
  * If more than MAX_LIST_LIKES likes, array will have one or two elements: ["\d+ other seamonkeys"] OR ["You", "\d+ other seamonkeys"]
* all_likes - null (if no likes), or an array
  * First element will be "You" if current_user likes the post: ["You", ...]
  * Array will include usernames all users who have liked the post: ["username_string", ...] OR ["You", "username_string", ...] 

* ReactionsSummary{} - A JSON object showing the counts of each reaction type. Will be { } if no reactions.
  ```
  {
      "reaction_word": \d+,
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
      "animated": boolean
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

### Seamail specific types

#### SeamailMessage{}

```
{
    "id": "seamail_message_id_string",
    "author": UserInfo{},
    "text": "string",
    "timestamp": "ISO_8601_DATETIME", # Date and time that this message was posted
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
    "messages": [ # Sorted by message timestamp descending. May be excluded from some endpoints that only return metadata.
        SeamailMessage{}, ...
    ],
    "message_count": integer # An integer counting the number of messages (or unread messages) in the thread
    "timestamp": "ISO_8601_DATETIME", # Date and time of the most recent message in the thread
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

* unread=&lt;boolean&gt; - Optional (Default: false) - only show unread seamail if true
* after=&lt;ISO_8601_DATETIME&gt; OR &lt;epoch&gt; - Optional (Default: all messages) - Only show seamail threads that have been updated after this point in time.
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
* after=&lt;ISO_8601_DATETIME&gt; OR &lt;epoch&gt; - Optional (Default: all messages) - Only show seamail threads and messages after this point in time.
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

#### Query parameters

none

#### JSON Request Body

```
{
    "users": [username_string, ...],   # A list of recipient usernames. No need to include the author, it will be automatically added. Duplicates will be ignored.
    "subject": "string",
    "text": "string"  # The first post's of the seamail's textual content
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
            "Must send seamail to another user of Twitarr", # No users in the user list
            "x is not a valid username", # No user exists with the username 'x'
            "Subject can't be blank",
            "Text can't be blank"
        ]
    }
  ```

### POST /api/v2/seamail/:id

Add a new message to an existing Seamail thread

#### Requires

* logged in.
    * Accepts: key query parameter

#### Query parameters

none

#### JSON Request Body

```
{
    "text": "string"
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
   { "status": "error", "errors": [ "Text can't be blank" ]}
   ```
### POST /api/v2/seamail/:id/recipients

Modifies the recipients of a seamail. Disabled until we figure out if/how we want to support this.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Query parameters

none

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
            "Must send seamail to another user of Twitarr", # No users in the user list
        ]
    }
   ```
### GET /api/v2/user/new_seamail

Get how many unread seamails the user has
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

#### StreamPost

```
{
    "id": "id_string",
    "author": UserInfo{},
    "timestamp": "ISO_8601_DATETIME",
    "text": "marked_up_text",
    "likes": likes_summary,
    "reactions": ReactionsSummary{},
    "photo": PhotoDetails{}, # photo will not be present if the post does not have a photo
    "parent_chain": [ "stream_post_id_string", ... ]
}
```

#### StreamPostThread

```
{
    "id": "id_string",
    "author": UserInfo{},
    "text": "marked up text",
    "timestamp": "ISO_8601_DATETIME",
    "likes": likes_summary,
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

#### Requires

#### Query parameters

* start=epoch - Optional (Default: Now) - The start location for getting tweets
* newer_posts=true - Optional (Default: false) - If this parameter is true, get tweets newer than start, otherwise get tweets older than start
* limit=Integer - Optional (Default: 20) - How many tweets to get
* author=username - Optional (Default: No Filter) - Filter by username specified
* hashtag=hashtag - Optional (Default: No Filter) - Filter by hashtag
* likes=username - Optional (Default: No Filter) - Return only posts liked by the username specified
* mentions=username - Optional (Default: No Filter) - Filter by mentions of username specified
* include_author=true - Optional (Default: false) - When filtering by mentions, include posts mentioning *or* written by the username specified
* starred=true - Optional (Default: false) - Return only posts by starred users (You must be logged in for this to work.)

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

### GET /api/v2/thread/:id

Get details of a stream post (tweet)
This will include the children posts (replies) to this tweet sorted in timestamp order

#### Requires

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
  * HTTP 400 if `limit < 1` or `page < 0`
    ```
    {
        "status": "error", 
        "error": "Limit must be greater than 0, Page must be greater than or equal to 0"
    }
    ```

### GET /api/v2/stream/m/:query

View a user's mentions stream. Will include all tweets that tag the user.

#### Requires

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

View a hash tag tweet stream

#### Requires

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
    "text": "Tweet content",
    "parent": "stream_post_id_string", # Optional
    "photo": "photo_id_string" # Optional
}
```

* Text is required.  This will be the text of the tweet to be posted.
* parent is optional.  If Specified, it will make this post a reply to another StreamPost by the stream_post_id_string passed in.
* photo is optional.  If Specified, it will make this post link in the photo that has already been uploaded with the photo_id_string passed in.

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
* status_code_with_error_list - HTTP 400 with a list of problems
  ```
    { 
        "status": "error", 
        "errors": [
            "Text can't be blank",
            "photo_id_string is not a valid photo id" # photo_id_string will be replaced with the posted photo id
        ]
    }
  ```
### GET /api/v2/tweet/:id

Gets a single tweet.

#### Requires

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
    { "status": "error", "error": "Post not found" }
   ```

### POST /api/v2/tweet/:id

Allows the user to edit the text or photo for this post.  Nothing else is modifyable. A user may only edit their own posts, unless they are an admin.

#### Requires

* logged in.
    * Accepts: key query parameter

#### JSON Request Body

```
{
    "text": "Tweet content",
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
        "error": "Post not found"
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
  * status_code_with_error_list - HTTP 400 with a list of problems
    ```
    { 
        "status": "error", 
        "errors": [
            "Text can't be blank",
            "photo_id_string is not a valid photo id" # photo_id_string will be replaced with the posted photo id
        ]
    }
    ```

### DELETE /api/v2/tweet/:id

Allows the user to delete a post. A user may only edit their posts, unless they are an admin.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Returns

No body.  200-OK

#### Error Responses
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    { 
        "status": "error", 
        "error": "Post not found"
    }
    ```
  * HTTP 403 if the user does not have permission to delete the tweet
    ```
    { 
        "status": "error", 
        "error": "You can not delete other users' posts" 
    }
    ```

### POST /api/v2/tweet/:id/like

Like a post

#### Requires

* logged in.
    * Accepts: key query parameter

#### Returns

Current users who like the post

```
{
    "status": "ok",
    "likes": likes_summary
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    {
        "status": "error",
        "error": "Post not found"
    }
    ```

### DELETE /api/v2/tweet/:id/like

Unlike a post

#### Requires

* logged in.
  * Accepts: key query parameter

#### Returns

Current users who like the post

```
{
    "status": "ok",
    "likes": likes_summary
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    { 
        "status": "error", 
        "error": "Post not found" 
    }
    ```

### GET /api/v2/tweet/:id/like

Get the current likes of a post

#### Requires

#### Returns

Current users who like the post

```
{
    "status": "ok",
    "likes": all_likes
}
```

#### Error Responses
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    { 
        "status": "error", 
        "error": "Post not found"
    }
    ```

### POST /api/v2/tweet/:id/react/:type

React to a post. Type must come from the list of valid reaction words.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Returns

All reactions that have been applied to the post.

```
{
    "status": "ok",
    "reactions": ReactionDetails{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    {
        "status": "error",
        "error": "Post not found"
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
        "error": "Invalid reaction: type}" # type will be replaced with the posted type
    }
    ```

### DELETE /api/v2/tweet/:id/react/:type

Remove reaction from a post. If `type` is not a valid reaction word, or if it has not been added to the post by the current user, this request will report success without making any modifications to the post.

#### Requires

* logged in.
  * Accepts: key query parameter

#### Returns

All reactions that have been applied to the post.

```
{
    "status": "ok",
    "reactions": ReactionDetails{}
}
```

#### Error Responses
* status_code_only - HTTP 401 if user is not logged in
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    {
        "status": "error",
        "error": "Post not found"
    }
    ```
  * HTTP 400 if `type` is not included
    ```
    {
        "status": "error",
        "error": "Reaction type must be included."
    }
    ```

### GET /api/v2/tweet/:id/react

Get the list of reactions that have been applied to a post

#### Requires

#### Returns

All reactions that have been applied to the post.

```
{
    "status": "ok",
    "reactions": ReactionDetails{}
}
```

#### Error Responses
* status_code_with_message
  * HTTP 404 if tweet with given ID is not found
    ```
    { 
        "status": "error", 
        "error": "Post not found"
    }
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

### GET api/v2/hashtag/repopulate

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

### POST /api/v2/user/new

Create a new user account. This will trow an error if it is called while logged in.

#### Query Params

All parameters are required. If any are missing, an error will be returned. 

* new_username - Username of the new user. If it is in use, an error will be returned.
* new_password - Password of the new user. Must be at least 6 characters. If it is less, an error will be returned.
* email - The user's email address.
* security_question - A prompt used in the forgot password process.
* security_answer - The answer to the security prompt.

#### Returns

If the user is successfully created, a JSON object will be returned with the authentication 'key' of the logged in user (see /api/v2/user/auth) along with the new user's profile information.

### GET /api/v2/user/auth

Log in user, returning a 'key' that can be used in each /api/v2 request that requires authentication.  This can be used
instead of having a session cookie.

### GET /api/v2/user/logout

Removes any session data for the request.  This really has no effect if using the 'key' style.

### GET /api/v2/user/whoami

Returns the logged in user's information

### GET /api/v2/user/autocomplete/:username

Get auto completion list for usernames.  Username string must be greater than 3, and not include the '@' symbol

### GET /api/v2/user/view/:username

View the user information

### GET /api/v2/user/photo/:username

Get the user's profile picture

#### Query args
* full=true - Optional(Default: false) - Returns a larger version of the profile image

#### Returns
[ binary data that makes up the photo ]

### POST /api/v2/user/photo

Modify the user's profile photo

### DELETE /api/v2/user/photo

Reset the user's profile to the default identicon image

## Forum information

Get/post new threads and posts to those threads

### Forum Specific types

    JSON ForumThreadMeta {
        "id": "id_string",
        "last_post_display_name": "display_name_string",
        "last_post_page": Integer,
        "last_post_username": "author_string",
        "posts": Integer,
        "subject": "subject_string",
        "timestamp": "ISO_8601_DATETIME"
    }

    JSON ForumThread {
        "id": "id_string",
        "latest_read": "ISO_8601_DATETIME", // Last time the user read the thread
        "subject": "subject_string",
        "next_page": null|Integer,
        "prev_page": null|Integer,
        "posts": Array[PostMeta {...}, ...]
    }

    JSON ForumPost {
        "id": "id_string",
        "forum_id": "forum_id_string",
        "author": "author_string",
        "display_name": "display_name_string",
        "likes": Array["username_string", ...],
        "new": boolean,
        "text": "text_string",
        "timestamp": "ISO_8601_DATETIME"
    }

### GET /api/v2/forums/

Returns the index of all threads. Can be paginated or mass list.

#### Requires

#### Query parameters

* page=integer - Optional - Used in conjunction with limit query, if not present will respond with all threads
* limit=integer - Optional - Used in conjunction with page query, will determine how many threads are shown per page

#### Returns

    JSON Object {
        "forums_meta": Array[ ForumThreadMeta {...}, ... ],
        "next_page": Integer,
        "prev_page": Integer
    }

### PUT /api/v2/forums

Creates a forum and it's first post.

### Requires

* logged in.
    * Accepts: key query parameters

#### Json Request Body

    JSON Object {
      "subject": "string",
      "text": "string",
      "photos": Array ["string", ...]
    }

### GET /api/v2/forums/thread/:id

Returns a thread and it's contained posts.

#### Requires

#### Query parameters

* page=integer - Optional - Used in conjunction with limit query, if not present will respond with all posts in the thread
* limit=integer - Optional - Used in conjunction with page query, will determine how many posts are shown per page

#### Returns
  
    JSON Object {
        "forum": ForumThreadMeta {...}
    }

### POST /api/v2/forums/thread/:id

Creates a new post in the thread

### Requires

* logged in.
    * Accepts: key query parameters

#### Json Request Body

    JSON Object {
      "text": "string",
      "photos": Array ["string", ...]
    }

#### Returns

  JSON Object {
          "forum_post": PostMeta {...}
      }

### GET /api/v2/forums/thread/:id/like/:post_id

Likes a specific post_id

#### Requires

* logged in.
    * Accepts: key query parameters

#### Returns

  JSON Object {
          "likes": Array ["username_string", ...]
      }

### GET /api/v2/forums/thread/:id/unlike/:post_id

Unlikes a specific post_id

#### Requires

* logged in.
    * Accepts: key query parameters

#### Returns

  JSON Object {
          "likes": Array ["username_string", ...]
      }

## Event Information

Get/post information on events.

### Stream specific types

    JSON Event {
        "id": "id_string",
        "author": "username_string",
        "display_name": "displayname_string",
        "title": "title_string",
        "location": "location_string",
        "start_time": "ISO_8601_DATETIME",
        "end_time": "ISO_8601_DATETIME",
        "signups": ["username_string", ...],
        "favorites": ["username_string", ...],
        "description": "marked up text",
        "max_signups": null|Integer
    }

### GET /api/v2/event/

#### Requires

#### Query parameters

* sort_by=variable name - Optional (Default: start_time) - First variable query is sorted by
* order=asc|desc - Optional (Default: desc) - Second variable query is searched by, ascending or descending

#### Returns

    JSON Object { "total_count": 5,
                  "events": Array[ Event {...}, ... ],
                }


### POST /api/v2/event/

Posts an event.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Json Request Body

    JSON Object {
      "title": "string",
      "start_time": "ISO_8601_DATETIME",
      "location": "string",
      "description": "string",
      "end_time": "ISO_8601_DATETIME",
      "max_signups": integer
    }
    

* Description, end_time and max_signups are all optional fields. 

#### Returns

    JSON Event {...}


### GET /api/v2/event/:id

Get details of an event.

#### Requires

#### Query parameters

#### Returns

    JSON Event {...}


### DELETE /api/v2/event/:id

Destroy an owned event.

#### Requires

* logged in.
    * Accepts: key query parameter

A user may only delete their events, unless they are an admin.

#### Returns

No body. 200-OK


### PUT /api/v2/event/:id

Allows the user to edit the description, location, start and end times and max signups. Title is not modifyable.

#### Requires

* logged in.
    * Accepts: key query parameter

A user may only edit their events, unless they are an admin.

#### Json Request Body

    JSON Object {
      "description": "string",
      "location": "string",
      "start_time": "ISO_8601_DATETIME",
      "end_time": "ISO_8601_DATETIME",
      "max_signups": integer
    }
    

#### Returns

    JSON Event {...}


### POST /api/v2/event/:id/signup

Allows the user to signup to an event.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Query parameters

#### Returns

    JSON Event {...}

### DELETE /api/v2/event/:id/signup

Allows the user to remove their signup from an event.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Query parameters

#### Returns

    JSON Event {...}

### POST /api/v2/event/:id/favorite

Allows the user to favorite an event.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Query parameters

#### Returns

    JSON Event {...}

### DELETE /api/v2/event/:id/favorite

Allows the user to remove their favorite from an event.

#### Requires

* logged in.
    * Accepts: key query parameter

#### Query parameters

#### Returns

    JSON Event {...}
