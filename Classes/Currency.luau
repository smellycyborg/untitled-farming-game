local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local TypedPromise = require(Packages:WaitForChild("typed-remote"))

local UpdateCurrency = TypedPromise.event("UpdateCurrency", ReplicatedStorage) :: TypedPromise.Event<number, number>

local Currency = {}
local CurrencyPerPlayer: {[Player]: {[string]: number}} = {}




function Currency.Add(player: Player, currencyType: string, amount: number): (number?, number?)
    if not RunService:IsClient() then
        return
    end

    local prevCurrency: number, updatedCurrencys: number

    if not CurrencyPerPlayer[player] then
        CurrencyPerPlayer[player] = {}
    end

    if not CurrencyPerPlayer[player][currencyType] then
        CurrencyPerPlayer[player][currencyType] = 0
    end

    prevCurrency = CurrencyPerPlayer[player][currencyType]

    CurrencyPerPlayer[player][currencyType] += amount

    updatedCurrencys = CurrencyPerPlayer[player][currencyType]

    UpdateCurrency:FireClient(player, prevCurrency, updatedCurrencys)

    return prevCurrency, updatedCurrencys
end




Currency.ClientObserver = UpdateCurrency




return Currency