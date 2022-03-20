module Graphics
  @@transition = nil
  STOP_WHILE_TRANSITION = true

  unless defined?(transition_KGC_SpecialTransition)
    class << Graphics
      alias transition_KGC_SpecialTransition transition
    end

    class << Graphics
      alias update_KGC_SpecialTransition update
    end
  end

  def self.transition(duration = 8,filename = "", vague = 20)
    duration = duration.floor
    if judge_special_transition(duration, filename)
      duration = 0
      filename = ""
    end
    begin
      transition_KGC_SpecialTransition(duration, filename, vague)
    rescue Exception
      if filename != ""
        transition_KGC_SpecialTransition(duration, "", vague)
      end
    end
    if STOP_WHILE_TRANSITION && !@_interrupt_transition
      while @@transition && !@@transition.disposed?
        update
      end
    end
  end

  def self.update
    update_KGC_SpecialTransition
=begin
    if Graphics.frame_count %40 == 0
      count = 0
      ObjectSpace.each_object(Object) { |o| count += 1 }
      echo("Objects: #{count}\r\n")
    end
=end
    @@transition.update if @@transition && !@@transition.disposed?
    @@transition = nil if @@transition && @@transition.disposed?
  end

  def self.judge_special_transition(duration,filename)
    return false if @_interrupt_transition
    ret = true
    if @@transition && !@@transition.disposed?
      @@transition.dispose
      @@transition = nil
    end
    dc = File.basename(filename).downcase
    case dc
    # Other coded transitions
    when "breakingglass";   @@transition = Transitions::BreakingGlass.new(duration)
    when "rotatingpieces";  @@transition = Transitions::ShrinkingPieces.new(duration, true)
    when "shrinkingpieces"; @@transition = Transitions::ShrinkingPieces.new(duration, false)
    when "splash";          @@transition = Transitions::SplashTransition.new(duration)
    when "random_stripe_v"; @@transition = Transitions::RandomStripeTransition.new(duration, 0)
    when "random_stripe_h"; @@transition = Transitions::RandomStripeTransition.new(duration, 1)
    when "zoomin";          @@transition = Transitions::ZoomInTransition.new(duration)
    when "scrolldown";      @@transition = Transitions::ScrollScreen.new(duration, 2)
    when "scrollleft";      @@transition = Transitions::ScrollScreen.new(duration, 4)
    when "scrollright";     @@transition = Transitions::ScrollScreen.new(duration, 6)
    when "scrollup";        @@transition = Transitions::ScrollScreen.new(duration, 8)
    when "scrolldownleft";  @@transition = Transitions::ScrollScreen.new(duration, 1)
    when "scrolldownright"; @@transition = Transitions::ScrollScreen.new(duration, 3)
    when "scrollupleft";    @@transition = Transitions::ScrollScreen.new(duration, 7)
    when "scrollupright";   @@transition = Transitions::ScrollScreen.new(duration, 9)
    when "mosaic";          @@transition = Transitions::MosaicTransition.new(duration)
    # GSC transitions
    when "circle";           @@transition = Transitions::Circle.new(duration)
    when "fading";           @@transition = Transitions::Fading.new(duration)
    when "boxout";           @@transition = Transitions::BoxOut.new(duration)
    when "distortion";       @@transition = Transitions::Distortion.new(duration)
    # Graphic transitions
    when "";                 @@transition = Transitions::FadeTransition.new(duration)
    else; ret = false
    end
    Graphics.frame_reset if ret
    return ret
  end
end


#===============================================================================
# Screen transition classes
#===============================================================================
module Transitions
  #=============================================================================
  #
  #=============================================================================
  class BreakingGlass
    def initialize(numframes)
      @disposed = false
      @numframes = numframes
      @opacitychange = (numframes<=0) ? 255 : 255.0/numframes
      cx = 6
      cy = 5
      @bitmap = Graphics.snap_to_bitmap
      if !@bitmap
        @disposed = true
        return
      end
      width  = @bitmap.width/cx
      height = @bitmap.height/cy
      @numtiles = cx*cy
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprites = []
      @offset = []
      @y = []
      for i in 0...@numtiles
        @sprites[i] = Sprite.new(@viewport)
        @sprites[i].bitmap = @bitmap
        @sprites[i].x = width*(i%cx)
        @sprites[i].y = height*(i/cx)
        @sprites[i].src_rect.set(@sprites[i].x,@sprites[i].y,width,height)
        @offset[i] = (rand(100)+1)*3.0/100.0
        @y[i] = @sprites[i].y
      end
    end
    
    def disposed?; @disposed; end
    
    def dispose
      if !disposed?
        @bitmap.dispose
        for i in 0...@numtiles
          @sprites[i].visible = false
          @sprites[i].dispose
        end
        @sprites.clear
        @viewport.dispose if @viewport
        @disposed = true
      end
    end
    
    def update
      return if disposed?
      continue = false
      for i in 0...@numtiles
        @sprites[i].opacity -= @opacitychange
        @y[i] += @offset[i]
        @sprites[i].y = @y[i]
        continue = true if @sprites[i].opacity>0
      end
      self.dispose if !continue
    end
  end
  
  #===============================================================================
  #
  #===============================================================================
  class ShrinkingPieces
    def initialize(numframes, rotation)
      @disposed = false
      @rotation = rotation
      @numframes = numframes
      @opacitychange = (numframes<=0) ? 255 : 255.0/numframes
      cx = 6
      cy = 5
      @bitmap = Graphics.snap_to_bitmap
      if !@bitmap
        @disposed = true
        return
      end
      width  = @bitmap.width/cx
      height = @bitmap.height/cy
      @numtiles = cx*cy
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprites = []
      for i in 0...@numtiles
        @sprites[i] = Sprite.new(@viewport)
        @sprites[i].bitmap = @bitmap
        @sprites[i].ox = width/2
        @sprites[i].oy = height/2
        @sprites[i].x = width*(i%cx)+@sprites[i].ox
        @sprites[i].y = height*(i/cx)+@sprites[i].oy
        @sprites[i].src_rect.set(width*(i%cx),height*(i/cx),width,height)
      end
    end
    
    def disposed?; @disposed; end
    
    def dispose
      if !disposed?
        @bitmap.dispose
        for i in 0...@numtiles
          @sprites[i].visible = false
          @sprites[i].dispose
        end
        @sprites.clear
        @viewport.dispose if @viewport
        @disposed = true
      end
    end
    
    def update
      return if disposed?
      continue = false
      for i in 0...@numtiles
        @sprites[i].opacity -= @opacitychange
        if @rotation
          @sprites[i].angle += 40
          @sprites[i].angle %= 360
        end
        @sprites[i].zoom_x = @sprites[i].opacity/255.0
        @sprites[i].zoom_y = @sprites[i].opacity/255.0
        continue = true if @sprites[i].opacity>0
      end
      self.dispose if !continue
    end
  end
  
  #===============================================================================
  #
  #===============================================================================
  class SplashTransition
    SPLASH_SIZE = 32
    
    def initialize(numframes, vague = 9.6)
      @duration = numframes
      @numframes = numframes
      @splash_dir = []
      @disposed = false
      if @numframes <= 0
        @disposed = true
        return
      end
      @buffer = Graphics.snap_to_bitmap
      if !@buffer
        @disposed = true
        return
      end
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprite = Sprite.new(@viewport)
      @sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      size = SPLASH_SIZE
      size = [size,1].max
      cells = Graphics.width*Graphics.height/(size**2)
      rows = Graphics.width/size
      rect = Rect.new(0,0,size,size)
      mag = 40.0/@numframes
      cells.times { |i|
        rect.x = i%rows*size
        rect.y = i/rows*size
        x = rect.x/size-(rows>>1)
        y = rect.y/size-((cells/rows)>>1)
        r = Math.sqrt(x**2+y**2)/vague
        @splash_dir[i] = []
        if r != 0
          @splash_dir[i][0] = x/r
          @splash_dir[i][1] = y/r
        else
          @splash_dir[i][0] = (x!= 0) ? x*1.5 : pmrand*vague
          @splash_dir[i][1] = (y!= 0) ? y*1.5 : pmrand*vague
        end
        @splash_dir[i][0] += (rand-0.5)*vague
        @splash_dir[i][1] += (rand-0.5)*vague
        @splash_dir[i][0] *= mag
        @splash_dir[i][1] *= mag
      }
      @sprite.bitmap.blt(0,0,@buffer,@buffer.rect)
    end
    
    def disposed?; @disposed; end
    
    def dispose
      return if disposed?
      @buffer.dispose if @buffer
      @buffer = nil
      @sprite.visible = false
      @sprite.bitmap.dispose
      @sprite.dispose
      @viewport.dispose if @viewport
      @disposed = true
    end
    
    def update
      return if disposed?
      if @duration == 0
        dispose
      else
        size = SPLASH_SIZE
        cells = Graphics.width*Graphics.height/(size**2)
        rows = Graphics.width/size
        rect = Rect.new(0, 0, size, size)
        buffer = @buffer
        sprite = @sprite
        phase = @numframes-@duration
        sprite.bitmap.clear
        cells.times { |i|
          rect.x = (i%rows)*size
          rect.y = (i/rows)*size
          dx = rect.x+@splash_dir[i][0]*phase
          dy = rect.y+@splash_dir[i][1]*phase
          sprite.bitmap.blt(dx,dy,buffer,rect)
        }
        sprite.opacity = 384*@duration/@numframes
        @duration -= 1
      end
    end
    
    private
    
    def pmrand
      return (rand(2)==0) ? 1 : -1
    end
  end
  
  #===============================================================================
  #
  #===============================================================================
  class RandomStripeTransition
    RAND_STRIPE_SIZE = 2
  
    def initialize(numframes,direction)
      @duration = numframes
      @numframes = numframes
      @disposed = false
      if @numframes<=0
        @disposed = true
        return
      end
      @buffer = Graphics.snap_to_bitmap
      if !@buffer
        @disposed = true
        return
      end
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprite = Sprite.new(@viewport)
      @sprite.bitmap = Bitmap.new(Graphics.width,Graphics.height)
      ##########
      @direction = direction
      size = RAND_STRIPE_SIZE
      bands = ((@direction==0) ? Graphics.width : Graphics.height)/size
      @rand_stripe_deleted = []
      @rand_stripe_deleted_count = 0
      ary = (0...bands).to_a
      @rand_stripe_index_array = ary.sort_by { rand }
      ##########
      @sprite.bitmap.blt(0,0,@buffer,@buffer.rect)
    end
  
    def disposed?; @disposed; end
  
    def dispose
      return if disposed?
      @buffer.dispose if @buffer
      @buffer = nil
      @sprite.visible = false
      @sprite.bitmap.dispose
      @sprite.dispose
      @viewport.dispose if @viewport
      @disposed = true
    end
  
    def update
      return if disposed?
      if @duration==0
        dispose
      else
        dir = @direction
        size = RAND_STRIPE_SIZE
        bands = ((dir==0) ? Graphics.width : Graphics.height)/size
        rect = Rect.new(0,0,(dir==0) ? size : Graphics.width,(dir==0) ? Graphics.height : size)
        buffer = @buffer
        sprite = @sprite
        count = (bands-bands*@duration/@numframes)-@rand_stripe_deleted_count
        while count > 0
          @rand_stripe_deleted[@rand_stripe_index_array.pop] = true
          @rand_stripe_deleted_count += 1
          count -= 1
        end
        sprite.bitmap.clear
        bands.to_i.times { |i|
          unless @rand_stripe_deleted[i]
            if dir==0
              rect.x = i*size
              sprite.bitmap.blt(rect.x,0,buffer,rect)
            else
              rect.y = i*size
              sprite.bitmap.blt(0,rect.y,buffer,rect)
            end
          end
        }
        @duration -= 1
      end
    end
  end
  
  #===============================================================================
  #
  #===============================================================================
  class ZoomInTransition
    def initialize(numframes)
      @duration = numframes
      @numframes = numframes
      @disposed = false
      if @numframes<=0
        @disposed = true
        return
      end
      @buffer = Graphics.snap_to_bitmap
      if !@buffer
        @disposed = true
        return
      end
      @width  = @buffer.width
      @height = @buffer.height
      @viewport = Viewport.new(0,0,@width,@height)
      @viewport.z = 99999
      @sprite = Sprite.new(@viewport)
      @sprite.bitmap = @buffer
      @sprite.ox = @width/2
      @sprite.oy = @height/2
      @sprite.x = @width/2
      @sprite.y = @height/2
    end
  
    def disposed?; @disposed; end
  
    def dispose
      return if disposed?
      @buffer.dispose if @buffer
      @buffer = nil
      @sprite.dispose if @sprite
      @viewport.dispose if @viewport
      @disposed = true
    end
  
    def update
      return if disposed?
      if @duration==0
        dispose
      else
        @sprite.zoom_x += 0.2
        @sprite.zoom_y += 0.2
        @sprite.opacity = (@duration-1)*255/@numframes
        @duration -= 1
      end
    end
  end
  
  #===============================================================================
  #
  #===============================================================================
  class ScrollScreen
    def initialize(numframes,direction)
      @numframes = numframes
      @duration = numframes
      @dir = direction
      @disposed = false
      if @numframes<=0
        @disposed = true
        return
      end
      @buffer = Graphics.snap_to_bitmap
      if !@buffer
        @disposed = true
        return
      end
      @width  = @buffer.width
      @height = @buffer.height
      @viewport = Viewport.new(0,0,@width,@height)
      @viewport.z = 99999
      @sprite = Sprite.new(@viewport)
      @sprite.bitmap = @buffer
    end
  
    def disposed?; @disposed; end
  
    def dispose
      return if disposed?
      @buffer.dispose if @buffer
      @buffer = nil
      @sprite.dispose if @sprite
      @viewport.dispose if @viewport
      @disposed = true
    end
  
    def update
      return if disposed?
      if @duration==0
        dispose
      else
        case @dir
        when 1 # down left
          @sprite.y += (@height/@numframes)
          @sprite.x -= (@width/@numframes)
        when 2 # down
          @sprite.y += (@height/@numframes)
        when 3 # down right
          @sprite.y += (@height/@numframes)
          @sprite.x += (@width/@numframes)
        when 4 # left
          @sprite.x -= (@width/@numframes)
        when 6 # right
          @sprite.x += (@width/@numframes)
        when 7 # up left
          @sprite.y -= (@height/@numframes)
          @sprite.x -= (@width/@numframes)
        when 8 # up
          @sprite.y -= (@height/@numframes)
        when 9 # up right
          @sprite.y -= (@height/@numframes)
          @sprite.x += (@width/@numframes)
        end
        @duration -= 1
      end
    end
  end
  
  #===============================================================================
  #
  #===============================================================================
  class MosaicTransition
    def initialize(numframes)
      @duration = numframes
      @numframes = numframes
      @disposed = false
      if @numframes<=0
        @disposed = true
        return
      end
      @buffer = Graphics.snap_to_bitmap
      if !@buffer
        @disposed = true
        return
      end
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprite = Sprite.new(@viewport)
      @sprite.bitmap = @buffer
      @bitmapclone = @buffer.clone
      @bitmapclone2 = @buffer.clone
    end
  
    def disposed?; @disposed; end
  
    def dispose
      return if disposed?
      @buffer.dispose if @buffer
      @buffer = nil
      @sprite.dispose if @sprite
      @viewport.dispose if @viewport
      @disposed = true
    end
  
    def update
      return if disposed?
      if @duration==0
        dispose
      else
        @bitmapclone2.stretch_blt(
           Rect.new(0,0,@buffer.width*@duration/@numframes,@buffer.height*@duration/@numframes),
           @bitmapclone,
           Rect.new(0,0,@buffer.width,@buffer.height))
        @buffer.stretch_blt(
           Rect.new(0,0,@buffer.width,@buffer.height),
           @bitmapclone2,
           Rect.new(0,0,@buffer.width*@duration/@numframes,@buffer.height*@duration/@numframes))
        @duration -= 1
      end
    end
  end
  
  #===============================================================================
  #
  #===============================================================================
  class FadeTransition
    def initialize(numframes)
      @duration = numframes
      @numframes = numframes
      @disposed = false
      if @duration<=0
        @disposed = true
        return
      end
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprite = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
      @sprite.bitmap.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(0,0,0))
      @sprite.opacity = 255
    end
  
    def disposed?; @disposed; end
  
    def dispose
      return if disposed?
      @sprite.dispose if @sprite
      @viewport.dispose if @viewport
      @disposed = true
    end
  
    def update
      return if disposed?
      if @duration==0
        dispose
      else
        @sprite.opacity = (@duration-1)*255/@numframes
        @duration -= 1
      end
    end
  end
  
  #===============================================================================
  # GSC wild battle - circle transition
  #===============================================================================
  class Circle
    def initialize(numframes)
      @numframes = numframes
      @duration = numframes
      @disposed = false
      @bitmap = BitmapCache.load_bitmap("Graphics/Transitions/encounterWild")
      if !@bitmap
        @disposed = true
        return
      end
      width  = @bitmap.width
      height = @bitmap.height
      cx = width/Graphics.width     # 28
      cy = height/Graphics.height   # 01
      @numtiles = cx*cy
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprites = []
      @frame = []
      @addzoom = 1
      for i in 0...@numtiles
        @sprites[i] = Sprite.new(@viewport)
        @sprites[i].ox = i*Graphics.width
        @sprites[i].visible = false
        @sprites[i].bitmap = @bitmap
        @frame[i] = i
      end
    end
  
    def disposed?; @disposed; end
  
    def dispose
      if !disposed?
        @bitmap.dispose
        for i in 0...@numtiles
          if @sprites[i]
            @sprites[i].visible = false
            @sprites[i].dispose
          end
        end
        @sprites.clear
        @viewport.dispose if @viewport
        @disposed = true
      end
    end
  
    def update
      return if disposed?
      if @duration==0
        dispose
      else
        if @duration > @frame.length
          @duration = @frame.length
        end
        count = @frame.length-@duration
        for i in 0...@frame.length
          if @frame[i]==count
            @sprites[i].visible = true
          end
        end
      end
      @duration -= 1
    end
  end
  
  #===============================================================================
  # GSC wild battle - fading transition
  #===============================================================================
  class Fading
    def initialize(numframes)
      @numframes = numframes
      @duration = numframes
      @disposed = false
      @bitmap = BitmapCache.load_bitmap("Graphics/Transitions/blacksquare")
      if !@bitmap
        @disposed = true
        return
      end
      width  = @bitmap.width
      height = @bitmap.height
      cx = Graphics.width/width     # 20
      cy = Graphics.height/height   # 18
      @numtiles = cx*cy
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprites = []
      @frame = []
      @addzoom = 1
      for i in 0...@numtiles
        @sprites[i] = Sprite.new(@viewport)
        @sprites[i].x = width*(i%cx)
        @sprites[i].y = height*(i/cx)
        @sprites[i].visible = false
        @sprites[i].bitmap = @bitmap
      end
      for n in 0...30
        @frame[n] = n
      end
    end
  
    def disposed?; @disposed; end
  
    def dispose
      if !disposed?
        @bitmap.dispose
        for i in 0...@numtiles
          if @sprites[i]
            @sprites[i].visible = false
            @sprites[i].dispose
          end
        end
        @sprites.clear
        @viewport.dispose if @viewport
        @disposed = true
      end
    end
  
    def update
      return if disposed?
      if @duration==0
        dispose
      else
        if @duration > @frame.length
          @duration = @frame.length
        end
        count = @frame.length-@duration
        for i in 0...@frame.length
          if @frame[i]==count
            for j in 0...@numtiles/@frame.length
              randX = rand(20)
              randY = rand(18)
              num = 20*randY+randX
              while @sprites[num].visible == true
                randX = rand(20)
                randY = rand(18)
                num = 20*randY+randX
              end
              @sprites[num].visible = true
            end
          end
        end
      end
      @duration -= 1
    end
  end
  
  #===============================================================================
  # GSC wild battle - boxout transition
  #===============================================================================
  class BoxOut
    def initialize(numframes)
      @numframes = numframes
      @duration = numframes
      @disposed = false
      @bitmap = BitmapCache.load_bitmap("Graphics/Transitions/blacksquare")
      if !@bitmap
        @disposed = true
        return
      end
      width  = @bitmap.width
      height = @bitmap.height
      cx = Graphics.width/width     # 20
      cy = Graphics.height/height   # 18
      @numtiles = cx*cy
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprites = []
      @frame = []
      for n in 0...30
        @frame[n] = n
        @sprites[n] = Sprite.new(@viewport)
        @sprites[n].x = Graphics.width/2 - width/2
        @sprites[n].y = Graphics.height/2 - height/2
        @sprites[n].visible = false
        @sprites[n].bitmap = @bitmap
      end
    end
  
    def disposed?; @disposed; end
  
    def dispose
      if !disposed?
        @bitmap.dispose
        for i in 0...@numtiles
          if @sprites[i]
            @sprites[i].visible = false
            @sprites[i].dispose
          end
        end
        @sprites.clear
        @viewport.dispose if @viewport
        @disposed = true
      end
    end
  
    def update
      return if disposed?
      if @duration==0
        dispose
      else
        if @duration > @frame.length
          @duration = @frame.length
        end
        count = @frame.length-@duration
        for i in 0...@frame.length
          zoomFactor = 2.0/3.0*(i+2)
          if @frame[i]==count
            @sprites[i].zoom_x = zoomFactor
            @sprites[i].zoom_y = zoomFactor * 0.9
            width2 = @bitmap.width * @sprites[i].zoom_x
            height2 = @bitmap.height * @sprites[i].zoom_y
            @sprites[i].x = Graphics.width/2 - width2/2
            @sprites[i].y = Graphics.height/2 - height2/2
            @sprites[i].visible = true
          end
        end
      end
      @duration -= 1
    end
  end
  
  #===============================================================================
  # GSC wild battle - distortion transition
  #===============================================================================
  class Distortion
    def initialize(numframes)
      @numframes = numframes
      @duration = numframes
      @disposed = false
      @bitmap = BitmapCache.load_bitmap("Graphics/Transitions/distortion")
      if !@bitmap
        @disposed = true
        return
      end
      width  = @bitmap.width
      height = @bitmap.height
      cx = width/Graphics.width     # 05
      cy = height/Graphics.height   # 01
      @numtiles = cx*cy
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprites = []
      @frame = []
      @addzoom = 1
      for n in 0...30
        @sprites[n] = Sprite.new(@viewport)
        # 30 frames but only 5 sprites so show each sprite for 6 frames
        @sprites[n].ox = (n/6)*Graphics.width
        @sprites[n].visible = false
        @sprites[n].bitmap = @bitmap
        @frame[n] = n
      end
    end
  
    def disposed?; @disposed; end
  
    def dispose
      if !disposed?
        @bitmap.dispose
        for i in 0...@numtiles
          if @sprites[i]
            @sprites[i].visible = false
            @sprites[i].dispose
          end
        end
        @sprites.clear
        @viewport.dispose if @viewport
        @disposed = true
      end
    end
  
    def update
      return if disposed?
      if @duration==0
        dispose
      else
        if @duration > @frame.length
          @duration = @frame.length
        end
        count = @frame.length-@duration
        for i in 0...@frame.length
          if @frame[i]==count
            @sprites[i].visible = true
          end
        end
      end
      @duration -= 1
    end
  end
end