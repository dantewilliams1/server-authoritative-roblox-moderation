# Security Model

This system uses a server-authoritative security model. The client is only responsible for sending moderation requests through the admin UI. The server validates every request before performing any action.

## Core Principles

- The client never directly bans, unbans, kicks, resets data, or edits records.
- All moderation actions are executed on the server.
- Every request is checked against administrator permissions before being processed.
- Discord audit logs are used to track moderator actions outside of Roblox.

## Permission Validation

Admin access is verified using Roblox group ranks and a configured staff list.

The system checks:

- Whether the sender is an administrator
- Whether the sender has enough rank to moderate the target
- Whether the requested action is valid
- Whether the target user exists

## Unauthorized Requests

If a non-admin fires the admin RemoteFunction, the request is treated as exploit behavior because regular players should not have access to admin UI or admin remotes.

Unauthorized requests are rejected and can trigger punishment.

## Abuse Prevention

The system includes:

- Server-side validation
- Client-side UI cooldowns
- Server-side request rate limiting
- Protected DataStore calls using pcall
- Sanitized webhook configuration
- External Discord audit logs

## Webhook Security

Webhook URLs are not included in this public repository. The uploaded code uses placeholder values only.

Production webhook URLs should always be stored privately and should never be committed to GitHub.

## Data Protection

The public version of this project removes private game data, real webhook URLs, and sensitive production settings.
