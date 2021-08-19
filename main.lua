--[[
    Flappy Bird Remake - Moheshaa
]]

-----------------------------------------------------------------

push = require 'push'

Class = require 'class'

--Bird Class
require 'Bird'

--Pipe Class
require 'Pipe'

--PipePair Class
require 'PipePair'

require 'StateMachine'
require 'states/BaseState'
require 'states/CountdownState'
require 'states/PlayState'
require 'states/ScoreState'
require 'states/TitleScreenState'

--DIMENSIONS
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
VIRTUAL_WIDTH = 512
VIRTUAL_HEIGHT = 288

--IMAGES
local background = love.graphics.newImage('background.png')
local backgroundScroll = 0

local ground = love.graphics.newImage('ground.png')
local groundScroll = 0


local BACKGROUND_SCROLL_SPEED = 30 
local GROUND_SCROLL_SPEED = 60

-- point at which we should loop our background back to X 0
local BACKGROUND_LOOPING_POINT = 413

--bird variable
local bird = Bird()

-- our table of spawning PipesPairs
local pipePairs = {}

-- our timer for spawning pipes
local spawnTimer = 0

-- initialize our last recorded Y value for a gap placement to base other gaps off of
local lastY = -PIPE_HEIGHT + math.random(80) + 20

-- scrolling variable to pause the game when we collide with a pipe
local scrolling = true

-----------------------------------------------------------------

function love.load()
    --FILTER
    love.graphics.setDefaultFilter('nearest', 'nearest')

    --TITLE
    love.window.setTitle('Flappy Bird - (by Moheshaa)')

    -- initialize our nice-looking retro text fonts
    smallFont = love.graphics.newFont('font.ttf', 8)
    mediumFont = love.graphics.newFont('flappy.ttf', 14)
    flappyFont = love.graphics.newFont('flappy.ttf', 28)
    hugeFont = love.graphics.newFont('flappy.ttf', 56)
    love.graphics.setFont(flappyFont)

    -- initialize our table of sounds
    sounds = {
        ['jump'] = love.audio.newSource('jump.wav', 'static'),
        ['explosion'] = love.audio.newSource('explosion.wav', 'static'),
        ['hurt'] = love.audio.newSource('hurt.wav', 'static'),
        ['score'] = love.audio.newSource('score.wav', 'static'),
    
    -- https://freesound.org/people/xsgianni/sounds/388079/
    ['music'] = love.audio.newSource('marios_way.mp3', 'static')
    }
    
        -- kick off music
        sounds['music']:setLooping(true)
        sounds['music']:play()

    --VIRTUAL RESOLUTION INITIALIZE
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })

    -- initialize state machine with all state-returning functions
    gStateMachine = StateMachine {
        ['title'] = function() return TitleScreenState() end,
        ['countdown'] = function() return CountdownState() end,
        ['play'] = function() return PlayState() end,
        ['score']  = function() return ScoreState() end
    }
    gStateMachine:change('title')


    -- initialize input table
    love.keyboard.keysPressed = {}
end


-----------------------------------------------------------------

function love.resize(w, h)
    push:resize(w, h)
end

-----------------------------------------------------------------

function love.keypressed(key)
    -- add to our table of keys pressed this frame
    love.keyboard.keysPressed[key] = true
    if key == 'escape' then
        love.event.quit()
    end
end


-----------------------------------------------------------------

--[[
    New function used to check our global input table for keys we activated during this frame, looked up by their string value.
]]
function love.keyboard.wasPressed(key)
    if love.keyboard.keysPressed[key] then
        return true
    else
        return false
    end 
end

-----------------------------------------------------------------

function love.update(dt)
    if scrolling then
        -- scroll background by preset speed * dt, looping back to 0 after the looping point
        backgroundScroll = (backgroundScroll + BACKGROUND_SCROLL_SPEED * dt) 
            % BACKGROUND_LOOPING_POINT

        -- scroll ground by preset speed * dt, looping back to 0 after the screen width passes
        groundScroll = (groundScroll + GROUND_SCROLL_SPEED * dt) 
            % VIRTUAL_WIDTH
        
        -- now, we just update the state machine, which defers to the right state
        gStateMachine:update(dt)


        spawnTimer = spawnTimer + dt
        if spawnTimer > 2 then
            -- modify the last Y coordinate we placed so pipe gaps aren't too far apart
            -- no higher than 10 pixels below the top edge of the screen,
            -- and no lower than a gap length (90 pixels) from the bottom
            local y = math.max(-PIPE_HEIGHT + 10, 
                math.min(lastY + math.random(-20, 20), VIRTUAL_HEIGHT - 90 - PIPE_HEIGHT))
            lastY = y
            
            table.insert(pipePairs, PipePair(y))
            spawnTimer = 0
        end

        --render Bird
        bird:update(dt)

        for k, pair in pairs(pipePairs) do
            pair:update(dt)

            --check to see if bird collided with the pipe
            for l, pipe in pairs(pair.pipes) do
                if bird:collides(pipe) then
                    --pause
                    scrolling = false
                end
            end
        end

        for k, pair in pairs(pipePairs) do
            if pair.remove then
                table.remove(pipePairs, k)
            end
        end
    end
    -- reset input table
    love.keyboard.keysPressed = {}
end



-----------------------------------------------------------------
function love.draw()
    push:start()
    
    -- draw the background starting at top left (0, 0)
    love.graphics.draw(background, -backgroundScroll, 0)
    gStateMachine:render()

    -- draw the ground on top of the background, toward the bottom of the screen
    love.graphics.draw(ground, -groundScroll, VIRTUAL_HEIGHT - 16)
    
    push:finish()
    
end

-----------------------------------------------------------------