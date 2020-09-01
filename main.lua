local utils = require("utils")

function love.load()
    local SOUND_PATH = "onandon.mp3"
    
    SND_WINDOW_SIZE = 800
    N_BINS = 25

    BAR_MAX_H, BAR_W = 200, 10
    BAR_SPACING = 10 + BAR_W
    BAR_H_XLATE = (love.graphics.getWidth() - N_BINS * BAR_SPACING) / 2
    BAR_V_XLATE = (love.graphics.getHeight() + BAR_MAX_H + 100) / 2
    BAR_TTL_W = (BAR_SPACING * (N_BINS - 1) + BAR_W)

    b = utils:load_audio(SOUND_PATH)
    res = utils:ones(N_BINS)
    
    RING_X = love.graphics.getWidth()/2
    RING_Y = love.graphics.getHeight() / 4 + 50
    RING_ROTOFFSET, RING_R = 0, 75
    
    seeking, progress = false, 0
    SEEK_BAR_X, SEEK_BAR_Y = BAR_H_XLATE, BAR_V_XLATE + 10
    SEEK_BAR_W, SEEK_BAR_H = BAR_TTL_W, 10
    
    paused = false
    sound, pb_time = love.audio.newSource(b["raws"]), 0
    ttl_min = math.floor(sound:getDuration()/60)
    ttl_sec = sound:getDuration() - ttl_min * 60
    ttl_time = tostring(ttl_min)  .. ":" .. ("%05.02f"):format(ttl_sec)
    sound:play()

    frame = 0
end

function love.update(dt)
    frame = frame + 1

    if paused or sound:isStopped() then 
        sound:pause() else sound:play() end
            
    if not sound:isStopped() then pb_time = sound:tell() end

    if not (seeking or paused) then
        RING_ROTOFFSET = RING_ROTOFFSET + dt/3
        if frame % 2 == 0 then
            local snd_window = utils:fetch_nsamples( b["raws"],
                        math.ceil(pb_time * b["rate"]), SND_WINDOW_SIZE)
            res = utils:lerp(
                utils:dynam_aggregate(
                    utils:apply_mat(utils:DCT_mat(SND_WINDOW_SIZE),
                                    snd_window),
                    N_BINS), 
                res, 0.3)
        end
    end

    seeking = false
    if love.mouse.isDown(1) then
        local x, y = love.mouse.getPosition()
        if utils:pointinrect( x, y, SEEK_BAR_X, SEEK_BAR_Y,
                                    SEEK_BAR_W, SEEK_BAR_H) then
            seeking = true
            pb_time = sound:getDuration() * (x - SEEK_BAR_X)/SEEK_BAR_W
            sound:seek(pb_time)
            sound:play() --  needed so seeking after stopping works
            sound:pause()
        end
    end
    progress = pb_time/sound:getDuration()
end

function love.mousereleased() 
    if seeking then 
        sound:play()
        seeking = false 
    end 
end

function love.keypressed(key)
    if key == "space" then 
        paused = not paused 
    end
end

function love.draw()
    love.graphics.printf("Music Visualizer - jryzkns 2020)", 0, 0, 600)

    res_draw = utils:ease(res)
    love.graphics.setLineWidth(5)
    for i = 1, #res do 
        local RING_ANGLE = RING_ROTOFFSET + i / N_BINS * 2 * math.pi
        love.graphics.line(
            RING_X + (RING_R - 10 * res_draw[i]) * math.cos(RING_ANGLE),
            RING_Y + (RING_R - 10 * res_draw[i]) * math.sin(RING_ANGLE),
            RING_X + (RING_R + 45 * res_draw[i]) * math.cos(RING_ANGLE),
            RING_Y + (RING_R + 45 * res_draw[i]) * math.sin(RING_ANGLE))
        love.graphics.rectangle( "fill",
            BAR_H_XLATE + (i - 1) * BAR_SPACING, BAR_V_XLATE, 
            BAR_W, -1 * BAR_MAX_H * res_draw[i])
    end

    love.graphics.setLineWidth(2)
    love.graphics.rectangle("fill", SEEK_BAR_X, SEEK_BAR_Y, SEEK_BAR_W * progress, SEEK_BAR_H)
    love.graphics.rectangle("line", SEEK_BAR_X, SEEK_BAR_Y, SEEK_BAR_W, SEEK_BAR_H)
    if seeking then
        local seek_min = math.floor(pb_time/60)
        local seek_sec = pb_time - seek_min * 60
        love.graphics.printf(
            tostring(seek_min) .. ":" .. ("%05.02f"):format(seek_sec) 
            .. " / " .. ttl_time,
            SEEK_BAR_X + SEEK_BAR_W + 10, SEEK_BAR_Y-1, 500)
    end
end