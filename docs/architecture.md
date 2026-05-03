# Architecture

This project is structured around a server-authoritative moderation pipeline.

The admin UI collects moderation input, but all actual moderation logic is handled by the server.

## High-Level Flow

Admin UI  
→ Client Admin Script  
→ RemoteFunction Request  
→ Server Events Handler  
→ Permission Validation  
→ Moderation Function  
→ DataStore Update / MessagingService Removal  
→ Discord Audit Log  

## Main Components

### Client Admin Script

The client script controls the admin UI and sends moderation requests to the server.

It does not directly perform moderation actions.

### Events Module

The Events module receives RemoteFunction requests from the client.

It handles:

- Request validation  
- Rate limiting  
- Target user resolution  
- Permission checks  
- Routing requests to the correct moderation function  

### Functions Module

The Functions module contains the core moderation logic.

It handles:

- Permanent bans  
- Temporary bans  
- Unbans  
- Player removal  
- Player data resets  
- Admin data requests  
- Discord audit logging  
- Ban checks when players join  

### Messaging Module

The Messaging module uses Roblox MessagingService to remove players across active servers.

When a user is banned or kicked, the system publishes a removal message so other live servers can remove that player if they are currently online.

### Settings Module

The Settings module stores configuration values such as:

- Group ID  
- Required admin rank  
- Required developer rank  
- DataStore names  
- Staff lists  
- Discord webhook placeholders  

In production, private values should be kept out of public repositories.

## Data Flow Example: Permanent Ban

Admin clicks "Ban Permanently"  
→ Client sends request  
→ Server verifies admin permissions  
→ Server resolves target username/UserId  
→ Ban data is saved to DataStore  
→ MessagingService publishes removal  
→ Player is removed from servers  
→ Discord receives audit log  

## DataStores Used

- Punish — stores ban status, reason, moderator, duration, and timestamp  
- Record — stores player win/loss data  
- ParkStreak — stores streak data  
- ParkLeaderboard — stores leaderboard values  

## Design Goal

The goal of this system is to centralize moderation actions on the server, reduce abuse risk, preserve player records, and create an external audit trail for moderator accountability.
