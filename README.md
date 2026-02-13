# StackSocial

A decentralized on-chain social and tipping platform built on the Stacks blockchain using Clarity smart contracts.

## Overview

StackSocial enables users to create profiles, share posts, and tip creators directly using STX tokens. The platform includes social features like following, profile management, and administrative moderation capabilities.

## Features

### User Management
- **Create Profile**: Users can create accounts with username and bio
- **Profile Data**: Stores user information including follower count and tips received
- **Ban System**: Admin moderation to ban/unban users

### Social Features
- **Create Posts**: Share content (up to 280 characters)
- **Follow/Unfollow**: Build a social graph by following other users
- **Follower Tracking**: Monitor follower count on profiles

### Monetization
- **Tip Posts**: Send STX tokens directly to post creators
- **Tip Tracking**: Posts and profiles track total tips received
- **Statistics**: View total tips and user count across the platform

## Smart Contract Structure

### Error Codes
- `ERR_NOT_FOUND (u100)`: Resource does not exist
- `ERR_INVALID_AMOUNT (u101)`: Invalid amount provided
- `ERR_ALREADY_EXISTS (u102)`: Profile already exists
- `ERR_NOT_OWNER (u103)`: Only owner can perform action
- `ERR_BANNED (u104)`: User is banned from this action

### Data Structures

**Profiles Map**
- `username`: ASCII string (32 chars max)
- `bio`: ASCII string (128 chars max)
- `banned`: Boolean status
- `followers`: Follower count
- `tips-received`: Total tips received

**Posts Map**
- `author`: Creator principal
- `content`: Post content (280 chars max)
- `timestamp`: Creation timestamp
- `tips`: Total tips on post

**Follows Map**
- Tracks follower/followed relationships as boolean keys

### Public Functions

#### `create-profile (username bio)`
Creates a new user profile. Returns error if profile already exists.

#### `create-post (content)`
Creates a new post. User must have a profile and cannot be banned. Returns post ID.

#### `tip (post-id amount)`
Sends STX to a post creator. Updates post tips and creator profile stats. Fails if creator is banned.

#### `follow (user)`
Follow another user. Cannot follow yourself. Increments follower count.

#### `unfollow (user)`
Unfollow a user. Must have existing follow relationship. Decrements follower count.

#### `set-ban (user status)`
Admin function to ban/unban users. Only contract owner can execute.

### Read-Only Functions

- `get-profile (user)`: Retrieve a user's profile information
- `get-post (id)`: Retrieve post details
- `get-total-users`: Get total user count
- `get-total-tips`: Get total tips distributed

## State Variables

- `owner`: Contract owner (deployer)
- `next-post-id`: Counter for post IDs
- `total-users`: Total number of profiles created
- `total-tips`: Cumulative tips distributed

## Usage

### Creating a Profile
```
(contract-call? .stacksocial create-profile "username" "My bio")
```

### Posting Content
```
(contract-call? .stacksocial create-post "Hello Stacks community!")
```

### Tipping a Post
```
(contract-call? .stacksocial tip u1 u1000000)
```

### Following Users
```
(contract-call? .stacksocial follow 'SP2X...)
(contract-call? .stacksocial unfollow 'SP2X...)
```

## Requirements

- Stacks blockchain environment
- Clarity smart contract runtime
- STX tokens for tipping functionality

## Development

### Files
- stacksocial.clar: Main smart contract
- stacksocial.test.ts: Test suite
- Clarinet.toml: Project configuration

### Testing
Run tests with your Clarity testing framework to validate all functionality.

## Security Considerations

- Ban system prevents banned users from posting and receiving tips
- Only contract owner can ban users
- Self-follow prevention in follow function
- Validation of amounts before token transfers

## Future Enhancements

- Native event emission for off-chain indexing
- Post deletion functionality
- Direct messaging system
- Token-based rewards/governance
- Post liking/commenting
e]

## Contact

[Your contact information]
