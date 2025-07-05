# CityTailor Collaboration Features Documentation

This document describes the collaboration features for the CityTailor travel planning application.

## Overview

The CityTailor backend now supports:

1. **Plan Sharing with Access Codes**
   - Every plan can be assigned a 6-digit access code
   - Plans can be accessed by anyone with the access code, without requiring a username
   - Access codes can be generated, regenerated, or removed by plan owners

2. **Collaborative Editing**
   - Users can add collaborators to their plans
   - Collaborators can have read or edit permissions
   - Plans shared with a user appear in their plan list

## API Endpoints

### Access Code Endpoints

#### Generate Access Code
```
PUT /backend/plans/plans.php?id={planId}&generate_access_code=true
Headers: X-User-Name: {username}
```
Response:
```json
{
  "message": "Access code generated successfully",
  "access_code": "123456"
}
```

#### Remove Access Code
```
PUT /backend/plans/plans.php?id={planId}&remove_access_code=true
Headers: X-User-Name: {username}
```
Response:
```json
{
  "message": "Access code removed successfully"
}
```

#### Access Plan with Code
```
GET /backend/plans/plans.php?access_code={code}
```
or
```
GET /backend/plans/plans.php
Headers: X-Access-Code: {code}
```
Response: The complete plan data

### Collaborator Endpoints

#### Add Collaborator
```
PUT /backend/plans/plans.php?id={planId}&add_collaborator=true
Headers: X-User-Name: {username}
Body:
{
  "collaborator": "username_to_add",
  "permission_level": "read" | "edit"
}
```
Response:
```json
{
  "message": "Collaborator added successfully"
}
```

#### Remove Collaborator
```
PUT /backend/plans/plans.php?id={planId}&remove_collaborator=true
Headers: X-User-Name: {username}
Body:
{
  "collaborator": "username_to_remove"
}
```
Response:
```json
{
  "message": "Collaborator removed successfully"
}
```

#### List Collaborators
```
PUT /backend/plans/plans.php?id={planId}&list_collaborators=true
Headers: X-User-Name: {username}
```
Response:
```json
{
  "owner": "owner_username",
  "isOwner": true | false,
  "collaborators": [
    {
      "username": "collaborator1",
      "permissionLevel": "read",
      "addedAt": "2025-06-10 15:30:45"
    },
    {
      "username": "collaborator2",
      "permissionLevel": "edit",
      "addedAt": "2025-06-11 09:15:22"
    }
  ]
}
```

## Database Schema Changes

### Plans Table
The `ct_plans` table has been updated with a new column:
- `access_code VARCHAR(6) DEFAULT NULL` - Stores the 6-digit access code

### New Collaborators Table
A new table `ct_plan_collaborators` has been created with the following structure:
```sql
CREATE TABLE IF NOT EXISTS ct_plan_collaborators (
    id INT AUTO_INCREMENT PRIMARY KEY,
    plan_id VARCHAR(50) NOT NULL,
    username VARCHAR(100) NOT NULL,
    permission_level ENUM('read', 'edit') NOT NULL DEFAULT 'read',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES ct_plans(id) ON DELETE CASCADE,
    UNIQUE KEY unique_collaboration (plan_id, username)
);
```

## Testing the Collaboration Features

You can test the collaboration features using the provided test script:
```
node test_collaboration.js
```

This script demonstrates:
1. Creating a plan
2. Generating an access code
3. Adding a collaborator
4. Accessing the plan as a collaborator
5. Accessing the plan using an access code
6. Listing all plans including collaborative ones

## Integration with Gemini Plan Generation

The Node.js server has been updated to automatically generate access codes when a plan is created without a username. The access code is returned in the API response, allowing users to share and access their plans without signing in.