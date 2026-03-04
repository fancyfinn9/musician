-- C3 = MIDI 60

local instruments = {}

local function load_instrument(name)
    local path = core.get_modpath("musician") .. "/data/instruments/"..name.."/instrument.json"
    local file = io.open(path, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()

    local data = core.parse_json(content)
    if not data then
        core.log("error", "Invalid JSON in instrument.json")
        return
    end
    instruments[name] = data
    core.log("[musician] Loaded instrument "..name)
end

load_instrument("electric_piano")
load_instrument("tuba")
load_instrument("trumpet")

local function load_song(name)
    local path = core.get_modpath("musician") .. "/data/songs/"..name.."/song.json"
    local file = io.open(path, "r")
    if not file then return end
    local content = file:read("*all")
    file:close()

    local data = core.parse_json(content)
    if not data then
        core.log("error", "Invalid JSON in song.json")
        return
    end
    return data
end

local function get_sound(note, instrument)
    note = tostring(note)
    if note:match("^[A-G]") then -- This is a note name
        local semitones = 0
        local current_char = 1
        local char = note:sub(current_char,current_char)

        if char == "C" then
            -- Do nothing :)
        elseif char == "D" then
            semitones = semitones + 2
        elseif char == "E" then
            semitones = semitones + 4
        elseif char == "F" then
            semitones = semitones + 5
        elseif char == "G" then
            semitones = semitones + 7
        elseif char == "A" then
            semitones = semitones + 9
        elseif char == "B" then
            semitones = semitones + 11
        end
        current_char = current_char + 1

        char = note:sub(current_char,current_char)
        if char:match("^[%b#]") then
            if char == "b" then
                semitones = semitones - 1
            elseif char == "#" then
                semitones = semitones + 1
            end
            current_char = current_char + 1
            char = note:sub(current_char,current_char)
        end

        if char == "-" then
            char = -1
        end

        -- This final character should be a number
        char = tonumber(char)
        note = ((char + 2) * 12) + semitones
    else -- This is a MIDI note number
        note = tonumber(note)
    end

    -- Now that we have our MIDI note, let's find the correct sample and calculate how much to pitch shift it

    if not instruments[instrument] then
        instrument = "electric_piano"
    end

    local instr = instruments[instrument]
    local chosen_sound = "1"
    for i, data in pairs(instr.sounds) do
        if tonumber(data.range_start) <= note and tonumber(data.range_end) >= note then
            chosen_sound = i
        end
    end

    local st_change = note - instr.sounds[chosen_sound].pitch
    -- st_change is now how many semitones we need to pitch up, eg 5 or -3
    local pitch = 2^(st_change / 12)
    return instrument.."_"..instr.sounds[chosen_sound].filename, pitch
end

local next_song_id = 1
local current_songs = {} -- {song = song, beat = 0, tempo = 120, players = {type="node", part="1", pos=xyz}}

core.register_globalstep(function(dtime)
    for i, song in pairs(current_songs) do
        -- Check if all parts are empty
        local full_parts = 0
        for k, v in pairs(song.song.parts) do
            full_parts = full_parts + 1
        end
        for _, part in pairs(song.song.parts) do
            if #part < 1 then
                full_parts = full_parts - 1
            end
        end

        if full_parts < 1 then
            current_songs[i] = nil
        elseif #song.players < 1 then
            current_songs[i] = nil
        else
            song.beat = (song.beat or 0) + (dtime * ((song.tempo or 60) / 60))
            for _, note in ipairs(song.song.parts.meta) do -- Process meta part
                if tonumber(note.beat) <= song.beat then
                    if note.type == "tempo" then
                        song.tempo = tonumber(note.value)
                    end
                else
                    break
                end
            end
            for _, player in ipairs(song.players) do -- Play the notes out loud
                for _, note in ipairs(song.song.parts[player.part]) do
                    if tonumber(note.beat) <= song.beat then
                        local filename, pitch = get_sound(note.note, song.song.instruments[player.part])
                        local pos
                        if player.type == "node" then
                            pos = player.pos
                        elseif player.type == "player" then
                            pos = player.obj:get_pos()
                        end
                        local sound = core.sound_play(filename, {gain = 1.0, pitch = pitch, pos = pos})
                        core.after((tonumber(note.length) or 1) * (60 / song.tempo), core.sound_stop, sound)
                    else
                        break
                    end
                end
            end

            for name, part in pairs(song.song.parts) do -- Discard the notes from the queue (from unused parts too)
                while true do
                    if #part < 1 then break end
                    local note = part[1]
                    if tonumber(note.beat) <= song.beat then
                        table.remove(part, 1)
                    else
                        break
                    end
                end
            end
        end
    end
end)

core.register_chatcommand("play", {
    func = function(player, name)
        local song = load_song(name)
        if not song then return false, "Could not load song" end
        local song_table = {song = table.copy(song), beat = 0, tempo = 60, players = {}}
        for i, part in pairs(song_table.song.parts) do
            if i ~= "meta" then
                table.insert(song_table.players, {type="player", part=i, obj=core.get_player_by_name(player)})
            end
        end
        current_songs[tostring(next_song_id)] = song_table
        next_song_id = next_song_id + 1
    end
})