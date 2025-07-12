--[[

local gif = GifImages.new(rbx, ExplosionImageIds, 0.05, false)
local connection
connection = gif.onFinish:Connect(function()
       gif:destroy()
       connection:Disconnect()
       connection = nil
      gif = nil
end)
gif:play()

]]

export type Gif = {
    rbx: ImageLabel,
    imageIds: {[number]: string},
    speed: number,
    looped: boolean,
    finish: BindableEvent,
    onFinish: RBXScriptSignal,
    currentCount: number,

    play: (self: Gif) -> nil,
    destroy: (self: Gif) -> nil,
}

local gif = {}

function gif.new(rbx: ImageLabel, imageIds: {[number]: string}, speed: number, looped: boolean): Gif
    local inst = {} :: Gif

    inst.rbx = rbx :: ImageLabel 
    inst.imageIds = imageIds :: {[number]: string}
    inst.speed = speed :: number
    inst.looped = looped :: boolean

    inst.finish = Instance.new("BindableEvent") :: BindableEvent
    inst.onFinish = inst.finish.Event

    inst.currentCount = 1

    return setmetatable(inst, gif)
end

function gif:play()
    task.spawn(function()
        while self.rbx do
            self.rbx.Image = self.imageIds[self.currentCount]

            task.wait(self.speed)

            self.currentCount += 1
            if self.looped == false and self.currentCount > #self.imageIds then
                self.finish:Fire()
                break
            elseif self.looped == true and self.currentCount > #self.imageIds then
                self.currentCount = 1
            end
        end

        self:destroy()
    end) 
end

function gif:destroy()
    if self.finish then
        self.finish:Destroy()
        self.finish = nil
    end
end

gif.__index = gif

return gif