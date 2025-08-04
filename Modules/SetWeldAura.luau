return function(character: Model, aura: Model)
    assert(character, "Missing Argument 1")
    assert(aura, "Missing Argument 2")

    if not character:IsA("Model") then
        error("Argument 1 is not a Model") 
    end
    if not aura:IsA("Model") then
        error("Argument 2 is not a Model")
    end

    local success = false
    local characterChildren = character:GetChildren()
    for _, part in characterChildren do 
        if not part:IsA("BasePart") then
            continue
        end

        local foundPart = aura:FindFirstChild(part.Name)
        if not foundPart then
            continue
        end

        local function weldPartsAligned(part0: BasePart, part1: BasePart): Weld
            part1.CFrame = part0.CFrame

            local weld = Instance.new("Weld")
            weld.Part0 = part0
            weld.Part1 = part1
            weld.C0 = CFrame.new()
            weld.C1 = CFrame.new()
            weld.Parent = part0
            return weld
        end

        aura.Parent = workspace

        foundPart.Transparency = 1
        foundPart.Name = `aura {part.Name}`
        foundPart.Parent = character

        weldPartsAligned(part, foundPart)
        success = true 
    end

    aura:Destroy()

    print(`weld is a {success}`)
end
