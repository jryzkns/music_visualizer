local utils = {}

function utils:load_audio(path)
    local sound_data = love.sound.newSoundData(path)
    local sampling_rate = sound_data:getSampleRate()
    local ttl_samples = sound_data:getSampleCount()
    return {    raws   = sound_data,
                rate   = sampling_rate,
                nsmpls = ttl_samples}
end

function utils:fetch_nsamples(d, s, N)
    local out = {}
    local num_samples = d:getSampleCount()
    for i = 1, N do
        out[i] = (num_samples > s + i - 1) 
                        and d:getSample(s + i - 1) or 0 
    end
    return out
end

-- adapted from programming assignment 1;
-- default precision level of 4 digits
function utils:printmatrix(M, noprint)
    noprint = noprint and noprint or false
    local buffer = ""
    for i = 1,#M do
        if type(M[i]) == "number" then 
            buffer = buffer .. string.format("%.4f", M[i]) .. "\t" 
        else
            for j = 1, #M[i] do
                buffer = buffer .. string.format("%.04f", M[i][j]) .. "\t"
                if #M == 1 then buffer = buffer .. "\n" end
            end
            buffer = buffer .. "\n"
        end
    end
    if not noprint then print(buffer) end
    return buffer
end

function utils:DCT_mat(N)
    local m = {}
    for i = 1,N do 
        m[i] = {}
        if i == 1 then 
            for j = 1, N do
                m[i][j] = 1/math.sqrt(N) 
            end
        else
            for j = 1, N do
                m[i][j] = math.sqrt(2/N) 
                    * math.cos(((2*(j-1) + 1) * (i-1) * math.pi)/(2*N))
            end
        end
    end
    return m
end

function utils:apply_mat(M, x)
    local res = {}
    for i = 1,#x do
        res[i] = 0
        for j = 1, #x do
            res[i] = res[i] + M[i][j] * x[j]
        end
    end
    return res
end

function utils:ttl_energy(x)
    local ttl_energy = 0
    for i = 1, #x do ttl_energy = ttl_energy + math.abs(x[i]) end
    return ttl_energy
end

function utils:flat_aggregate(x, N)
    local aggregated = {}
    local aggregate_window = math.floor(#x/N)
    local energy = utils:ttl_energy(x)
    energy = energy > 0 and energy  or 1
    for j = 1, N do
        aggregated[j] = 0
        for k = 1, aggregate_window do
            aggregated[j] = aggregated[j] 
                + math.abs(x[(j - 1) * aggregate_window + k]) / energy
        end
    end
    return aggregated
end

function utils:dynam_aggregate(x, N, stepsize)
    local aggregated = {}
    local aggregate_window = 2
    local energy = utils:ttl_energy(x)
    energy = energy > 0 and energy  or 1
    stepsize = stepsize and stepsize or 2
    local rolling_ind = 1
    for j = 1, N do
        aggregated[j] = 0
        for k = 1, aggregate_window do
            aggregated[j] = aggregated[j] 
                + math.abs(x[rolling_ind])/energy
            rolling_ind = rolling_ind+ 1 <= #x and rolling_ind + 1 or #x
        end
        aggregate_window = aggregate_window + stepsize
    end
    return aggregated
end

function utils:lerp(a, b, weight)
    weight = weight and weight or 0.5
    local out = {}
    for i = 1, #a do 
        out[i] = weight * a[i]  + (1 - weight) * b[i]
    end
    return out
end

function utils:ease(x)
    local out = {}
    for i = 1, #x do out[i] = math.sqrt(2 * x[i]) end -- sqrt
    -- for i = 1, #x do out[i] = 6 * x[i]^5 - 15 * x[i]^4 + 10 * x[i]^3 end -- perlin
    -- for i = 1, #x do out[i] = 1/(1 + math.exp(-1*(10*(x[i]-0.4)))) end -- sigmoid
    -- for i = 1, #x do out[i] = x[i] end -- identity
    return out
end

-- returns a table of ones or a specific value
function utils:ones(N, val) 
    val = val and val or 1
    local out = {}; for i = 1,N do out[i] = val end
    return out
end

function utils:pointinrect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

return utils