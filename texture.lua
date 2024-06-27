--[[
	GPU-side texture utilities
]]

local texture = {}

-------------------------------------------------------------------------------
--	(helpers)
-------------------------------------------------------------------------------

--alias in case it's not already done globally
local lg = love.graphics

local function push_canvas(target)
	lg.push("all")
	lg.origin()
	lg.setColor(1, 1, 1, 1)
	lg.setShader()
	lg.setCanvas(target)
end

-------------------------------------------------------------------------------
--	copy - just pull pixels from one texture into another
-------------------------------------------------------------------------------

function texture.copy(from, to)
	push_canvas(to)
	lg.setBlendMode("replace", "premultiplied")
	lg.draw(from)
	lg.pop()
	return to
end

-------------------------------------------------------------------------------
--	downsampling - transform a large texture to a smaller texture
--
--	different modes provided for different use cases
--		eg supersampled antialiasing, gpu occlusion
-------------------------------------------------------------------------------

local downsample_template = [[
uniform float scale_factor;
uniform vec2 big_res;
uniform vec2 small_res;
#ifdef PIXEL
vec4 effect(vec4 c, Image t, vec2 uv, vec2 px) {
	vec2 big_uv_origin_px = (floor(uv * small_res) / small_res) * big_res + vec2(0.5);
	vec4 accum = vec4(<init>);
	for (float oy = 0; oy < scale_factor; oy++) {
		for (float ox = 0; ox < scale_factor; ox++) {
			vec2 ouv = (big_uv_origin_px + vec2(ox, oy)) / big_res;
			vec4 px = Texel(t, ouv);
			<op>
		}
	}
	return <res>;
}
#endif
]]

local function create_downsample_shader(init, op, res)
	local src = downsample_template
	src = src:gsub("<init>", init)
	src = src:gsub("<op>", op)
	src = src:gsub("<res>", res)

	return lg.newShader(src)
end

local downsample_shaders = {
	--box average
	average = create_downsample_shader(
		"0.0",
		"accum += px;",
		"accum / (scale_factor * scale_factor)"
	),
	--min/max filter
	min = create_downsample_shader(
		"1e6",
		"accum = min(accum, px);",
		"accum"
	),
	max = create_downsample_shader(
		"-1e6",
		"accum = max(accum, px);",
		"accum"
	),
	--magnitude only
	abs_min = create_downsample_shader(
		"1e6",
		"accum = min(accum, abs(px));",
		"accum"
	),
	abs_max = create_downsample_shader(
		"-1e6",
		"accum = max(accum, abs(px));",
		"accum"
	),
}

function texture.downsample(big, small, op)
	local shader = downsample_shaders[op]
	if not shader then
		error("unknown op for texture.downsample, " .. tostring(op))
	end
	local scale_factor = big:getWidth() / small:getWidth()
	if scale_factor ~= math.floor(scale_factor) then
		error("texture.downsample needs an integer scaling factor")
	end
	if scale_factor == 1 then
		return texture.copy(big, small)
	end
	lg.push("all")
	lg.setCanvas(small)
	local downscale_factor = 1 / scale_factor
	shader:send("scale_factor", scale_factor)
	shader:send("big_res", {big:getDimensions()})
	shader:send("small_res", {small:getDimensions()})
	lg.setShader(shader)
	lg.draw(big, 0, 0, 0, downscale_factor, downscale_factor)
	lg.pop()
	return small
end

-------------------------------------------------------------------------------
--	todo: texture.upsample in various flavours
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--	dilate/erode
--
--	find the maximum or minimum in a neighbourhood
--		eg expanding visible areas to include their neighbouring walls
-------------------------------------------------------------------------------

local dilate_shader = lg.newShader([[
uniform vec2 res;
uniform float distance;
uniform int op_id;
#ifdef PIXEL
vec4 effect(vec4 c, Image t, vec2 uv, vec2 px) {
	vec4 colour = Texel(t, uv);
	for (float oy = -distance; oy <= distance; oy++) {
		for (float ox = -distance; ox <= distance; ox++) {
			float a = 1.0;
			vec2 o = vec2(ox, oy);
			if (length(o) <= distance) {
				o /= res;
				if (op_id == 1) {
					colour = min(colour, Texel(t, uv + o));
				} else {
					colour = max(colour, Texel(t, uv + o));
				}
			}
		}
	}
	return colour;
}
#endif
]])

--todo: codegen instead of runtime switch
local dilate_operations = {
	min = 1,
	max = 2,
}

function texture.dilate(from, to, distance, operation)
	local op_id = dilate_operations[operation]
	if not op_id then
		error("unknown operation for texture.dilate, "..operation)
	end
	dilate_shader:send("distance", distance)
	dilate_shader:send("res", {from:getDimensions()})
	dilate_shader:send("op_id", op_id)
	lg.push("all")
	lg.setCanvas(to)
	lg.setShader(dilate_shader)
	lg.draw(from)
	lg.pop()
	return to
end

-------------------------------------------------------------------------------
--	blur
--
--	a 2-pass separated box or gaussian blur
-------------------------------------------------------------------------------

local blur_shader = lg.newShader([[
uniform vec2 res;
uniform float steps;
uniform vec2 dimension;
uniform bool gaussian;
#ifdef PIXEL
vec4 effect(vec4 c, Image t, vec2 uv, vec2 px) {
	vec4 colour = vec4(0.0);
	float total = 0.0;
	for (float oi = -steps; oi <= steps; oi++) {
		float a = 1.0;
		vec2 o = dimension * oi;
		if (gaussian) {
			a = mix(1.0, 0.0, length(o) / (steps + 1.0));
		}
		if (a > 0) {
			o /= res;
			colour += Texel(t, uv + o) * a;
			total += a;
		}
	}
	return colour / total;
}
#endif
]])

function texture.blur(from, partial, to, steps, gaussian)
	blur_shader:send("steps", steps)
	blur_shader:send("res", {from:getDimensions()})
	blur_shader:send("gaussian", gaussian or false)
	lg.push("all")
	lg.setShader(blur_shader)
	blur_shader:send("dimension", {1, 0})
	lg.setCanvas(partial)
	lg.draw(from)
	blur_shader:send("dimension", {0, 1})
	lg.setCanvas(to)
	lg.draw(partial)
	lg.pop()
	return to
end

-------------------------------------------------------------------------------
--	todo: sharpen
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--	todo: generic convolution
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--	todo: mip generation
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--	todo: jump flood
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--	todo: whole texture lerp a, b, t
-------------------------------------------------------------------------------

return texture