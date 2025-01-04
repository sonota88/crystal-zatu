require "sdl-crystal-bindings"

alias SdlWindow = Pointer(Void)
alias SdlRenderer = Pointer(Void)
alias ArgbColor = Array(Int32)

module DXCrystal
  C_WHITE = [255, 255, 255, 255]
  C_RED = [255, 255, 0, 0]

  class Color
    getter r : UInt8, g : UInt8, b : UInt8, a : UInt8

    def initialize(@r, @g, @b, @a = 0xff) end

    def self.from_argb(argb : ArgbColor) : Color
      case argb.size
      when 3
        Color.new(
          argb[0].to_u8,
          argb[1].to_u8,
          argb[2].to_u8,
          0xff.to_u8
        )
      when 4
        Color.new(
          argb[1].to_u8,
          argb[2].to_u8,
          argb[3].to_u8,
          argb[0].to_u8
        )
      else
        raise "panic"
      end
    end

    def to_sdl_color : LibSDL::Color
      c = LibSDL::Color.new
      c.r = @r
      c.g = @g
      c.b = @b
      c.a = @a
      c
    end
  end

  class FpsManager
    SPAN_1SEC = Time::Span.new(seconds: 1)

    property fps, count, real_fps
    property span_acc # accumulated span
    getter span_per_frame
    def initialize(
          @fps = 60,
          @count = 0,
          @span_acc = Time::Span.new(nanoseconds: 0)
        )
      @real_fps = @fps
      @span_per_frame = Time::Span.new(nanoseconds: 1_000_000_000 // @fps)
    end
  end

  module Window
    @@width = 640
    @@height = 480
    @@bgcolor = Color.new(0xf4, 0xf4, 0xf4, 0xff)
    @@fpsm = FpsManager.new

    @@sdl_window : SdlWindow?
    @@sdl_renderer : SdlRenderer?

    def self.width=(width)
      @@width = width
    end

    def self.width() @@width end

    def self.height=(height)
      @@height = height
    end

    def self.height() @@height end

    def self.bgcolor=(bgcolor : ArgbColor)
      @@bgcolor = Color.from_argb(bgcolor)
    end

    def self.load_resources
      yield
    end

    def self.init_sdl
      if LibSDL.init(LibSDL::INIT_VIDEO) != 0
        raise "SDL could not initialize! Error: #{String.new(LibSDL.get_error)}"
      end

      @@sdl_window = LibSDL.create_window(
        "(window title)",
        LibSDL::WINDOWPOS_UNDEFINED,
        LibSDL::WINDOWPOS_UNDEFINED,
        Window.width,
        Window.height,
        LibSDL::WindowFlags::WINDOW_SHOWN
      )
      unless @@sdl_window
        raise "Window could not be created! Error: #{String.new(LibSDL.get_error)}"
      end

      @@sdl_renderer = LibSDL.create_renderer(
        @@sdl_window.not_nil!,
        -1,
        LibSDL::RendererFlags::RENDERER_ACCELERATED
      )
      unless @@sdl_renderer
        raise "Renderer could not be created! SDL Error: #{String.new(LibSDL.get_error)}"
      end

      LibSDL.set_render_draw_blend_mode(
        @@sdl_renderer.not_nil!,
        LibSDL::BlendMode::BLENDMODE_BLEND
      )
    end

    def self._fill_bg(renderer : SdlRenderer)
      LibSDL.set_render_draw_color(
        renderer,
        @@bgcolor.r, @@bgcolor.g, @@bgcolor.b, @@bgcolor.a
      )
      LibSDL.render_fill_rect(renderer, nil)
    end

    def self.loop
      init_sdl()
      renderer = @@sdl_renderer.not_nil!

      # frame = proc + sleep
      t_base_frame = Time.local
      t_base_proc = Time.local

      quit = false

      ::loop do
        while LibSDL.poll_event(out e) != 0
          if e.type == LibSDL::EventType::QUIT.to_i
            quit = true
          end
        end
        break if quit

        _fill_bg(renderer)
        yield
        LibSDL.render_present(renderer)

        t_now = Time.local
        @@fpsm.count += 1
        span_frame = t_now - t_base_frame
        @@fpsm.span_acc += span_frame
        t_base_frame = t_now

        if @@fpsm.span_acc > FpsManager::SPAN_1SEC
          @@fpsm.span_acc -= FpsManager::SPAN_1SEC
          @@fpsm.real_fps = @@fpsm.count
          @@fpsm.count = 0
          puts "fps: #{@@fpsm.real_fps}"
        end

        t_delta = Time.local - t_base_proc
        if t_delta < @@fpsm.span_per_frame
          span_sleep = @@fpsm.span_per_frame - t_delta
          sleep span_sleep
        end
        t_base_proc = Time.local
      end

      LibSDL.destroy_renderer(renderer)
      LibSDL.destroy_window(@@sdl_window.not_nil!)

      LibSDL.quit
    end

    def self._sdl_fpoint(x, y) : LibSDL::FPoint
      fp = LibSDL::FPoint.new
      fp.x = x
      fp.y = y
      fp
    end

    def self._sdl_vertex(position, color) : LibSDL::Vertex
      v = LibSDL::Vertex.new
      v.position = position
      v.color = color
      v
    end

    def self._draw_triangle(
          x1, y1,
          x2, y2,
          x3, y3,
          color : LibSDL::Color
        )
      vertices = [
        _sdl_vertex(_sdl_fpoint(x1, y1), color),
        _sdl_vertex(_sdl_fpoint(x2, y2), color),
        _sdl_vertex(_sdl_fpoint(x3, y3), color)
      ]

      LibSDL.render_geometry(
        @@sdl_renderer.not_nil!,
        nil, # texture
        vertices, vertices.size,
        nil, 0 # indices
      )
    end

    def self.draw_circle_fill(
          x, y, r,
          color : ArgbColor,
          z = 0
        )
      c = Color.from_argb(color).to_sdl_color

      n = 16
      pi2 = Math::PI * 2

      (0..n)
        .map { |i|
          rad = pi2 * (i.to_f / n)
          x2 = x + Math.cos(rad) * r
          y2 = y + Math.sin(rad) * r
          { x2, y2 }
        }
        .each_cons(2) { |pt_pair|
          pt1, pt2 = pt_pair
          _draw_triangle(x, y, *pt1, *pt2, c)
        }
    end
  end
end
