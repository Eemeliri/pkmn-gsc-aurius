#==============================================================================
# ** Game_Map
#------------------------------------------------------------------------------
#  This class handles the map. It includes scrolling and passable determining
#  functions. Refer to "$game_map" for the instance of this class.
#==============================================================================
class Game_Map
  attr_accessor :map_id
  attr_accessor :tileset_name             # tileset file name
  attr_accessor :autotile_names           # autotile file name
  attr_reader   :passages                 # passage table
  attr_reader   :priorities               # prioroty table
  attr_reader   :terrain_tags             # terrain tag table
  attr_reader   :events                   # events
  attr_accessor :panorama_name            # panorama file name
  attr_accessor :panorama_hue             # panorama hue
  attr_accessor :fog_name                 # fog file name
  attr_accessor :fog_hue                  # fog hue
  attr_accessor :fog_opacity              # fog opacity level
  attr_accessor :fog_blend_type           # fog blending method
  attr_accessor :fog_zoom                 # fog zoom rate
  attr_accessor :fog_sx                   # fog sx
  attr_accessor :fog_sy                   # fog sy
  attr_reader   :fog_ox                   # fog x-coordinate starting point
  attr_reader   :fog_oy                   # fog y-coordinate starting point
  attr_reader   :fog_tone                 # fog color tone
  attr_accessor :battleback_name          # battleback file name
  attr_reader   :display_x                # display x-coordinate * 128
  attr_reader   :display_y                # display y-coordinate * 128
  attr_accessor :need_refresh             # refresh request flag

  TILE_WIDTH  = 32
  TILE_HEIGHT = 32
  X_SUBPIXELS = ($RPGVX) ? 8 : 4
  Y_SUBPIXELS = ($RPGVX) ? 8 : 4
  REAL_RES_X  = TILE_WIDTH * X_SUBPIXELS
  REAL_RES_Y  = TILE_HEIGHT * Y_SUBPIXELS

  def initialize
    @map_id = 0
    @display_x = 0
    @display_y = 0
  end

  def setup(map_id)
    @map_id               = map_id
    @map = load_data(sprintf("Data/Map%03d.%s",map_id,($RPGVX) ? "rvdata" : "rxdata"))
    tileset = $data_tilesets[getTilesetID(@map.tileset_id)]
    updateTileset
    @fog_ox               = 0
    @fog_oy               = 0
    @fog_tone             = Tone.new(0, 0, 0, 0)
    @fog_tone_target      = Tone.new(0, 0, 0, 0)
    @fog_tone_duration    = 0
    @fog_opacity_duration = 0
    @fog_opacity_target   = 0
    self.display_x        = 0
    self.display_y        = 0
    @need_refresh         = false
    Events.onMapCreate.trigger(self,map_id,@map,tileset)
    @events               = {}
    for i in @map.events.keys
      @events[i]          = Game_Event.new(@map_id, @map.events[i],self)
    end
    @common_events        = {}
    for i in 1...$data_common_events.size
      @common_events[i]   = Game_CommonEvent.new(i)
    end
    @scroll_direction     = 2
    @scroll_rest          = 0
    @scroll_speed         = 4
  end

#===================================================================================
# GSC Swap Tilesets System
# Numbers indicate the tileset ID in the Database.
# TIMESENSITIVETILESETSMORN compile the data for morning tilesets.
#   - It's active when switch PBDayNight.isMorning? is ON.
# TIMESENSITIVETILESETSEVENING compile the data for night-tone tilesets.
#   - It's active when switch PBDayNight.isNight? is ON.
#===================================================================================

TIMESENSITIVETILESETSMORN = {        # Tilesets change list for the morning
  1 => 2,
  4 => 5,
  40 => 42,
  41 => 42,
  46 => 47
}
TIMESENSITIVETILESETSEVENING = {        # Tilesets change list for the night
  1 => 3,
  4 => 6,
  40 => 43,
  41 => 43,
  46 => 48
}

def getTilesetID(id)
  if(TIMESENSITIVETILESETSMORN.include?(id) && PBDayNight.isMorning?(pbGetTimeNow))
    return TIMESENSITIVETILESETSMORN[id]
elsif (TIMESENSITIVETILESETSEVENING.include?(id) && PBDayNight.isNight?(pbGetTimeNow))
    return TIMESENSITIVETILESETSEVENING[id]
  else
     return id
   end
 end
#===================================================================================

  def updateTileset
    tileset = $data_tilesets[getTilesetID(@map.tileset_id)]
    @tileset_name    = tileset.tileset_name
    @autotile_names  = tileset.autotile_names
    @panorama_name   = tileset.panorama_name
    @panorama_hue    = tileset.panorama_hue
    @fog_name        = tileset.fog_name
    @fog_hue         = tileset.fog_hue
    @fog_opacity     = tileset.fog_opacity
    @fog_blend_type  = tileset.fog_blend_type
    @fog_zoom        = tileset.fog_zoom
    @fog_sx          = tileset.fog_sx
    @fog_sy          = tileset.fog_sy
    @battleback_name = tileset.battleback_name
    @passages        = tileset.passages
    @priorities      = tileset.priorities
    @terrain_tags    = tileset.terrain_tags
  end

  def width;          return @map.width;          end
  def height;         return @map.height;         end
  def encounter_list; return @map.encounter_list; end
  def encounter_step; return @map.encounter_step; end
  def data;           return @map.data;           end

  def name
    ret = pbGetMessage(MessageTypes::MapNames,@map_id)
    ret.gsub!(/\\PN/,$Trainer.name) if $Trainer
    return ret
  end
  #-----------------------------------------------------------------------------
  # * Autoplays background music
  #   Plays music called "[normal BGM]_n" if it's night time and it exists
  #-----------------------------------------------------------------------------
  def autoplayAsCue
    if @map.autoplay_bgm
      if PBDayNight.isNight? && FileTest.audio_exist?("Audio/BGM/"+ @map.bgm.name+ "_n")
        pbCueBGM(@map.bgm.name+"_n",1.0,@map.bgm.volume,@map.bgm.pitch)
      else
        pbCueBGM(@map.bgm,1.0)
      end
    end
    if @map.autoplay_bgs
      pbBGSPlay(@map.bgs)
    end
  end
  #-----------------------------------------------------------------------------
  # * Plays background music
  #   Plays music called "[normal BGM]_n" if it's night time and it exists
  #-----------------------------------------------------------------------------
  def autoplay
    if @map.autoplay_bgm
      if PBDayNight.isNight? && FileTest.audio_exist?("Audio/BGM/"+ @map.bgm.name+ "_n")
        pbBGMPlay(@map.bgm.name+"_n",@map.bgm.volume,@map.bgm.pitch)
      else
        pbBGMPlay(@map.bgm)
      end
    end
    if @map.autoplay_bgs
      pbBGSPlay(@map.bgs)
    end
  end

  def valid?(x, y)
     return (x>=0 and x<width and y>=0 and y<height)
  end

  def validLax?(x, y)
    return (x>=-10 and x<=width+10 and y>=-10 and y<=height+10)
  end

  def passable?(x, y, d, self_event = nil)
    return false if !valid?(x, y)
    bit = (1 << (d / 2 - 1)) & 0x0f
    for event in events.values
      next if event.tile_id <= 0
      terrain = @terrain_tags[event.tile_id]
      next if terrain == PBTerrain::Neutral
      next if event == self_event
      next if !event.at_coordinate?(x, y)
      next if event.through
      passage = @passages[event.tile_id]
      return false if passage & bit != 0
      return false if passage & 0x0f == 0x0f
      return true if @priorities[event.tile_id] == 0
    end
    return playerPassable?(x, y, d, self_event) if self_event==$game_player
    # All other events
    newx = x; newy = y
    case d
    when 1; newx -= 1; newy += 1
    when 2;            newy += 1
    when 3; newx += 1; newy += 1
    when 4; newx -= 1
    when 6; newx += 1
    when 7; newx -= 1; newy -= 1
    when 8;            newy -= 1
    when 9; newx += 1; newy -= 1
    end
    return false if !valid?(newx, newy)
    for i in [2, 1, 0]
      tile_id = data[x, y, i]
      terrain = @terrain_tags[tile_id]
      passage = @passages[tile_id]
      # If already on water, only allow movement to another water tile
      if self_event!=nil && PBTerrain.isJustWater?(terrain)
        for j in [2, 1, 0]
          facing_tile_id = data[newx, newy, j]
          return false if facing_tile_id==nil
          facing_terrain = @terrain_tags[facing_tile_id]
          if facing_terrain!=0 && facing_terrain!=PBTerrain::Neutral
            return PBTerrain.isJustWater?(facing_terrain)
          end
        end
        return false
      # Can't walk onto ice
      elsif PBTerrain.isIce?(terrain)
        return false
      elsif self_event!=nil && self_event.x==x && self_event.y==y
        # Can't walk onto ledges
        for j in [2, 1, 0]
          facing_tile_id = data[newx, newy, j]
          return false if facing_tile_id==nil
          facing_terrain = @terrain_tags[facing_tile_id]
          if facing_terrain!=0 && facing_terrain!=PBTerrain::Neutral
            return false if PBTerrain.isLedge?(facing_terrain)
            break
          end
        end
        # Regular passability checks
        if terrain!=PBTerrain::Neutral
          if passage & bit != 0 || passage & 0x0f == 0x0f
            return false
          elsif @priorities[tile_id] == 0
            return true
          end
        end
      # Regular passability checks
      elsif terrain!=PBTerrain::Neutral
        if passage & bit != 0 || passage & 0x0f == 0x0f
          return false
        elsif @priorities[tile_id] == 0
          return true
        end
      end
    end
    return true
  end

  def playerPassable?(x, y, d, self_event = nil)
    bit = (1 << (d / 2 - 1)) & 0x0f
    for i in [2, 1, 0]
      tile_id = data[x, y, i]
      terrain = @terrain_tags[tile_id]
      passage = @passages[tile_id]
      # Ignore bridge tiles if not on a bridge
      next if PBTerrain.isBridge?(terrain) && $PokemonGlobal.bridge==0
      # Make water tiles passable if player is surfing
      if $PokemonGlobal.surfing && PBTerrain.isPassableWater?(terrain)
        return true
      # Prevent cycling in really tall grass/on ice
      elsif $PokemonGlobal.bicycle && PBTerrain.onlyWalk?(terrain)
        return false
      # Depend on passability of bridge tile if on bridge
      elsif PBTerrain.isBridge?(terrain) && $PokemonGlobal.bridge>0
        return (passage & bit == 0 && passage & 0x0f != 0x0f)
      # Regular passability checks
      elsif terrain!=PBTerrain::Neutral
        if passage & bit != 0 || passage & 0x0f == 0x0f
          return false
        elsif @priorities[tile_id] == 0
          return true
        end
      end
    end
    return true
  end

  # Returns whether the position x,y is fully passable (there is no blocking
  # event there, and the tile is fully passable in all directions)
  def passableStrict?(x, y, d, self_event = nil)
    return false if !valid?(x, y)
    for event in events.values
      next if event == self_event || event.tile_id < 0 || event.through
      next if !event.at_coordinate?(x, y)
      terrain = @terrain_tags[event.tile_id]
      next if terrain == PBTerrain::Neutral
      return false if @passages[event.tile_id] & 0x0f != 0
      return true if @priorities[event.tile_id] == 0
    end
    for i in [2, 1, 0]
      tile_id = data[x, y, i]
      terrain = @terrain_tags[tile_id]
      next if terrain == PBTerrain::Neutral
      return false if @passages[tile_id] & 0x0f != 0
      return true if @priorities[tile_id] == 0
    end
    return true
  end

  def bush?(x,y)
    for i in [2, 1, 0]
      tile_id = data[x, y, i]
      return false if PBTerrain.isBridge?(@terrain_tags[tile_id]) && $PokemonGlobal.bridge>0
      return true if @passages[tile_id] & 0x40 == 0x40
    end
    return false
  end

  def deepBush?(x,y)
    for i in [2, 1, 0]
      tile_id = data[x, y, i]
      terrain = @terrain_tags[tile_id]
      return false if $PokemonGlobal.bridge>0 && PBTerrain.isBridge?(terrain)
      return true if terrain==PBTerrain::TallGrass && @passages[tile_id] & 0x40 == 0x40
    end
    return false
  end

  def counter?(x,y)
    for i in [2, 1, 0]
      tile_id = data[x, y, i]
      passage = @passages[tile_id]
      return true if passage & 0x80 == 0x80
    end
    return false
  end

  def terrain_tag(x,y,countBridge=false)
    return 0 if !valid?(x, y)
    for i in [2, 1, 0]
      tile_id = data[x, y, i]
      terrain = @terrain_tags[tile_id]
      next if !countBridge && PBTerrain.isBridge?(terrain) && $PokemonGlobal.bridge==0
      return terrain if terrain > 0 && terrain!=PBTerrain::Neutral
    end
    return 0
  end

  def check_event(x,y)
    for event in self.events.values
      return event.id if event.at_coordinate?(x, y)
    end
  end

  def display_x=(value)
    @display_x = value
    if pbGetMetadata(self.map_id,MapMetadata::SNAP_EDGES)
      max_x = (self.width - Graphics.width*1.0/TILE_WIDTH) * REAL_RES_X
      @display_x = [0, [@display_x, max_x].min].max
    end
    $MapFactory.setMapsInRange if $MapFactory
  end

  def display_y=(value)
    @display_y = value
    if pbGetMetadata(self.map_id,MapMetadata::SNAP_EDGES)
      max_y = (self.height - Graphics.height*1.0/TILE_HEIGHT) * REAL_RES_Y
      @display_y = [0, [@display_y, max_y].min].max
    end
    $MapFactory.setMapsInRange if $MapFactory
  end

  def scroll_up(distance)
    self.display_y -= distance
  end

  def scroll_down(distance)
    self.display_y += distance
  end

  def scroll_left(distance)
    self.display_x -= distance
  end

  def scroll_right(distance)
    self.display_x += distance
  end

  def start_scroll(direction, distance, speed)
    @scroll_direction = direction
    if direction==2 || direction==8   # down or up
      @scroll_rest = distance * REAL_RES_Y
    else
      @scroll_rest = distance * REAL_RES_X
    end
    @scroll_speed = speed
  end

  def scrolling?
    return @scroll_rest > 0
  end

  def start_fog_tone_change(tone,duration)
    @fog_tone_target = tone.clone
    @fog_tone_duration = duration
    if @fog_tone_duration == 0
      @fog_tone = @fog_tone_target.clone
    end
  end

  def start_fog_opacity_change(opacity,duration)
    @fog_opacity_target = opacity*1.0
    @fog_opacity_duration = duration
    if @fog_opacity_duration==0
      @fog_opacity = @fog_opacity_target
    end
  end

  def refresh
    for event in @events.values
      event.refresh
    end
    for common_event in @common_events.values
      common_event.refresh
    end
    @need_refresh = false
  end

  def update
    # refresh maps if necessary
    if $MapFactory
      for i in $MapFactory.maps
        i.refresh if i.need_refresh
      end
      $MapFactory.setCurrentMap
    end
    # If scrolling
    if @scroll_rest>0
      distance = (1<<@scroll_speed)*40.0/Graphics.frame_rate
      distance = @scroll_rest if distance>@scroll_rest
      case @scroll_direction
      when 2; scroll_down(distance)
      when 4; scroll_left(distance)
      when 6; scroll_right(distance)
      when 8; scroll_up(distance)
      end
      @scroll_rest -= distance
    end
    # Only update events that are on-screen
    for event in @events.values
      event.update
    end
    # Update common events
    for common_event in @common_events.values
      common_event.update
    end
    # Update fog
    @fog_ox -= @fog_sx/8.0
    @fog_oy -= @fog_sy/8.0
    if @fog_tone_duration>=1
      d = @fog_tone_duration
      target = @fog_tone_target
      @fog_tone.red   = (@fog_tone.red * (d - 1) + target.red) / d
      @fog_tone.green = (@fog_tone.green * (d - 1) + target.green) / d
      @fog_tone.blue  = (@fog_tone.blue * (d - 1) + target.blue) / d
      @fog_tone.gray  = (@fog_tone.gray * (d - 1) + target.gray) / d
      @fog_tone_duration -= 1
    end
    if @fog_opacity_duration >= 1
      d = @fog_opacity_duration
      @fog_opacity = (@fog_opacity * (d - 1) + @fog_opacity_target) / d
      @fog_opacity_duration -= 1
    end
  end
end
