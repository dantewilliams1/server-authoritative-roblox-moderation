# Server-Authoritative Roblox Moderation System

A moderation and audit logging system built for Hoop Central 6, a live Roblox multiplayer game with 67M+ total visits.

The system allows authorized staff to ban users, unban users, remove players from active servers, reset player data, and request moderation records. All moderation actions are validated on the server and logged externally through Discord webhooks for audit tracking.

## Features

- Permanent and temporary ban support
- Server-side administrator validation
- Group-rank based permission checks
- Developer/admin hierarchy protection
- DataStore-based punishment records
- Cross-server player removal using MessagingService
- Discord webhook logging for bans, unbans, record resets, and data requests
- Player record reset tools for wins, losses, streaks, and leaderboard data
- Admin UI that submits requests without controlling final moderation logic

## System Flow

1. Moderator opens the in-game admin panel.
2. Moderator selects an action such as ban, unban, kick, reset record, or request data.
3. Client sends a request to the server through a RemoteFunction.
4. Server validates the moderator using group rank and staff configuration.
5. Server resolves the target player by username or UserId.
6. Selected action is executed server-side.
7. DataStores are updated if needed.
8. MessagingService removes the player from active servers when applicable.
9. Discord webhook log is sent for audit tracking.

## Security Model

The client never performs moderation directly. The client only sends a request. The server verifies the sender before performing any action.

Unauthorized users cannot execute admin actions because every RemoteFunction request is checked server-side.

## Tech Stack

- Roblox Luau
- Roblox RemoteFunctions
- Roblox DataStores
- Roblox MessagingService
- Discord Webhooks
- Server-side authorization

## Scale

- Built for Hoop Central 6
- 67M+ total visits
- Designed for live multiplayer servers with 20–25 players per server
- Used for frequent moderation and anti-cheat related actions

## Disclaimer

This repository contains sanitized portfolio code. Private webhook URLs, production settings, and sensitive internal game logic have been removed.

## Portfolio Note

This project is a sanitized version of a production moderation system built for Hoop Central 6. It is intended to demonstrate backend architecture, server-authoritative security, DataStore persistence, cross-server messaging, and audit logging. Private production values and sensitive game logic have been removed.
