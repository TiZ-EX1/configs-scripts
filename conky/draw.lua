require 'cairo'

tl = 0; tr = 1; br = 2; bl = 3

local function rgba_tuple (color)
	return ((color / 0x1000000) % 0x100) / 255.,
		   ((color / 0x10000) % 0x100) / 255.,
		   ((color / 0x100) % 0x100) / 255.,
		   (color % 0x100) / 255.
end

local function check_ql ()
	local test = io.open(os.getenv("HOME").."/.quodlibet/current", "r")
	if test == nil then
		return false
	else
		test:close()
		local test = io.open("/tmp/.current.song", "r")
		if test == nil then
			return false
		else
			test:close()
			return true
		end
	end
end

-- Draw a translucent background on the window.
-- color: RGBA hex string
-- tl, tr, br, bl: corner radii
function conky_draw (color, tl, tr, br, bl)
	if conky_window == nil then return end
	local w = conky_window.width
	local h = conky_window.height
	if h <= 20 then return end
	
	local cs = cairo_xlib_surface_create(
	 conky_window.display,
	 conky_window.drawable,
	 conky_window.visual, w, h)
	local cr = cairo_create(cs)
	
	cairo_move_to(cr, tl, 0)
	cairo_line_to(cr, w-tr, 0)
	cairo_curve_to(cr, w-tr, 0, w, 0, w, tr)
	cairo_line_to(cr, w, h-br)
	cairo_curve_to(cr, w, h-br, w, h, w-br, h)
	cairo_line_to(cr, bl, h)
	cairo_curve_to(cr, bl, h, 0, h, 0, h-bl)
	cairo_line_to(cr, 0, tl)
	cairo_curve_to(cr, 0, tl, 0, 0, tl, 0)
	cairo_close_path(cr)

	cairo_set_source_rgba(cr, rgba_tuple(color))
	cairo_fill(cr)

	cairo_surface_destroy(cs)
	cairo_destroy(cr)
end

-- Draw a translucent background and the cover at /tmp/conkycover.png.
-- color: RGBA hex string
-- tl, tr, br, bl: corner radii
-- top, bottom: displacement of background from top/bottom edges
-- x, y: displacement of cover
-- right: 0 for left align, 1 for right align
-- middle: 0 for regular, 1 to cut off the backround in the middle of the cover
function conky_draw_ql (color, tl, tr, br, bl, top, bottom, x, y, right, middle)
	if conky_window == nil then return end
	if not check_ql() then return end
	if top == nil then top = 0 end
	if bottom == nil then bottom = 0 end
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	right = tonumber(right) ~= 0
	middle = tonumber(middle) ~= 0
	local w = conky_window.width
	local h = conky_window.height - bottom
	local left = 0
	local img_w = 0
	
	local cs = cairo_xlib_surface_create(
	  conky_window.display,
	  conky_window.drawable,
	  conky_window.visual, w, h)
	local cr = cairo_create(cs)
	
	local image = cairo_image_surface_create_from_png("/tmp/conkycover.png")
	if image then img_w = cairo_image_surface_get_width(image) end
	if middle then if right then w = w - img_w / 2 else left = img_w / 2 end end
	
	cairo_move_to(cr, left+tl, top)
	cairo_line_to(cr, w-tr, top)
	cairo_curve_to(cr, w-tr, top, w, top, w, top+tr)
	cairo_line_to(cr, w, h-br)
	cairo_curve_to(cr, w, h-br, w, h, w-br, h)
	cairo_line_to(cr, left+bl, h)
	cairo_curve_to(cr, left+bl, h, left, h, left, h-bl)
	cairo_line_to(cr, left, top+tl)
	cairo_curve_to(cr, left, top+tl, left, top, left+tl, top)
	cairo_close_path(cr)
	
	cairo_set_source_rgba(cr, rgba_tuple(color))
	cairo_fill(cr)
	
	if image then
		if right then
			if middle then x = x + w - img_w / 2
			else x = x + w - img_w end
		end
		cairo_set_source_surface(cr, image, x, y)
		cairo_paint(cr)
	end

	cairo_surface_destroy(cs)
	cairo_surface_destroy(image)
	cairo_destroy(cr)
end
