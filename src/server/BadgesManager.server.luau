local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

local Packages = ReplicatedStorage.Packages
local Classes = ReplicatedStorage.Classes
local Modules = ReplicatedStorage.Modules

local Badges = require(Modules.Badges)

Badges.InitServer()