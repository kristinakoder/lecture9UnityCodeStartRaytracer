﻿
// Fra https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509640(v=vs.85).aspx
//https://msdn.microsoft.com/en-us/library/windows/desktop/ff471421(v=vs.85).aspx
// rand num generator http://gamedev.stackexchange.com/questions/32681/random-number-hlsl
// http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
// https://docs.unity3d.com/Manual/RenderDocIntegration.html
// https://docs.unity3d.com/Manual/SL-ShaderPrograms.html

Shader "Unlit/SingleColor"
{
	Properties
	{
	// inputs from gui, NB remember to also define them in "redeclaring" section
	[Toggle] _boolchooser("myBool", Range(0,1)) = 0  // [Toggle] creates a checkbox in gui and gives it 0 or 1
	_floatxaxis("xAxis", Range(0,1)) = 0
	_refractionIndex("Refraction Index", Range(0,3)) = 0
	_maxbounces("max bounses", Range(1,100)) = 10
	_raysprpixel("Rays per pixel", Range(1,1000)) = 1
	_camerapos("Camera position", Vector) = (0,0,0)
	_cameralookatpos("Camera Look-at position", Vector) = (0,0,0)
	_colorchooser("myColor", Color) = (1,0,0,1)
	//_texturechooser("myTexture", 2D) = "" {} // "" er for bildefil, {} er for options
	}

		SubShader{ Pass	{
			
	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

	// redeclaring gui inputs
	int _boolchooser;
	float _raysprpixel;
	float _refractionIndex;
	float _maxbounces;
	float _floatxaxis;
	float3 _camerapos;
	float3 _cameralookatpos;
	float4 _colorchooser;// alternative use fixed4;  range of –2.0 to +2.0 and 1/256th precision. (https://docs.unity3d.com/Manual/SL-DataTypesAndPrecision.html)
	
	//sampler2D _texturechooser;

	float2 random_seed = float2(0.0, 0.0);
	float random_incr = 0.0;

		typedef vector <float, 3> vec3;  // to get more similar code to book
		typedef vector <fixed, 3> col3;
	
	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		return o;
	}
	
	float rand()
	{
		float2 noise = (frac(sin(dot(float2(random_seed.x+random_incr,random_seed.y+random_incr), float2(12.9898, 78.233)*2.0)) * 43758.5453));
		random_incr += 0.01; 
		return abs(noise.x + noise.y) * 0.5;
	}

	//returnerer en random, normalisert vektor
	vec3 random_on_hemisphere(vec3 normal)
	{
		vec3 v = 2.0 * vec3(rand(), rand(), rand()) - vec3(1.0, 1.0, 1.0);
		v = normalize(v);
		v *= rand();
		return (dot(v, normal) > 0.0) ? v : -v;
	}

	class ray
	{
		void make(vec3 orig, vec3 dir) { _origin = orig; _direction = dir; } // constructors not supported in hlsl
		vec3 at(float t) { return _origin + _direction*t; }
		vec3 _origin;			// private members not supported, these public members will 
		vec3 _direction;			// be accessed directly from outside 
	};

	class hit_record
	{
		void set_face_normal(ray r, vec3 outward_normal)
		{
			front_face = dot(r._direction, outward_normal) < 0;
			normal = front_face ? outward_normal : -outward_normal;
		}
		vec3 p;
		vec3 normal;
		float t;
		bool front_face;
	};
	
	class sphere
	{
		void make(vec3 c, float r) {center = c; radius = r;}
		
		bool hit(ray r, float ray_tmin, float ray_tmax, out hit_record rec)
		{
			vec3 oc = r._origin - center;
			float a = dot(r._direction, r._direction);
			float half_b = dot(oc, r._direction);
			float c = dot(oc, oc) - radius * radius;
			float discriminant = half_b * half_b - a * c;

			if (discriminant < 0) return false;
			
			float sqrtd = sqrt(discriminant);

			float root = (-half_b - sqrtd) / a;
			if (root <= ray_tmin || ray_tmax <= root) 
			{
				root = (-half_b + sqrtd) / a;
				if (root <= ray_tmin || ray_tmax <= root)
					return false;
			}
	
			rec.t = root;
			rec.p = r.at(rec.t);
			vec3 outward_normal = (rec.p - center) / radius;
			rec.set_face_normal(r, outward_normal);
	
			return true;
		}
		
		vec3 center;
		float radius;
		float materialtype;
		vec3 matproperties;
	};

	void getsphere(int i, out sphere sph)
	{
		if (i == 0) { sph.center = vec3( 0, 0, -1); sph.radius = 0.5; sph.materialtype = 0; sph.matproperties.xyz = vec3(0.8, 0.3, 0.3);}
		if (i == 1) { sph.center = vec3( 0,-100.5, -1); sph.radius = 100; sph.materialtype = 0; sph.matproperties.xyz = vec3(0.8, 0.8, 0.0);}
		if (i == 2) { sph.center = vec3( 1, 0, -1); sph.radius = 0.5; sph.materialtype = 1; sph.matproperties.xyz = vec3(0.8, 0.6, 0.2);}
		if (i == 3) { sph.center = vec3(-1, 0, -1); sph.radius = 0.5; sph.materialtype = 1; sph.matproperties.xyz = vec3(0.8, 0.8, 0.8);}
	}

	bool world_hit(ray r, float min, float max, out hit_record rec)
	{
		hit_record temp_rec = (hit_record) 0;
		bool found_hit = false;
		float closest_so_far = max;
		for (int i = 0; i < 2; i++)
		{
			sphere s;
			getsphere(i, s);
			if (s.hit(r, min, closest_so_far, temp_rec))
			{
				found_hit = true;
				closest_so_far = temp_rec.t;
				rec = temp_rec;
			}
		}
		return found_hit;
	}

	col3 ray_color(ray r)
	{
		hit_record rec = (hit_record) 0;
		col3 accumCol = {1,1,1};

		while (world_hit(r, 0.001, 1000000, rec) && _maxbounces > 0)
		{
			_maxbounces--;
			vec3 randdir = rec.normal + random_on_hemisphere(rec.normal); 
			r.make(rec.p, randdir);
			accumCol *= 0.9;
		}
			
		if (_maxbounces == 0)
			return col3(0,0,0);	
		
		vec3 unit_direction = normalize(r._direction);
		float y = 0.5*(unit_direction.y + 1.0); 
		return accumCol * ((1.0-y)*col3(1.0,1.0,1.0) + y*col3(0.5,0.7,1.0));
	}

	fixed4 frag(v2f i) : SV_Target 
	{
		vec3 lower_left_corner = {-2, -1, -1};
		vec3 horizontal = {4, 0, 0};
		vec3 vertical = {0, 2, 0};
		vec3 origin = {0, 0, 0};

		float x = i.uv.x;
		float y = i.uv.y;
		random_seed = i.uv;
		
		ray r;
		col3 col = {0,0,0};
		for (int i = 0; i < _raysprpixel; i++)
		{
			r.make(origin, lower_left_corner + ((0.003 * rand())+x)*horizontal + ((0.003 * rand())+y)*vertical);
			col += ray_color(r);
		}
		col /= _raysprpixel;
		
		col = sqrt(col); //gamma
		return fixed4(col,1); 
	}

ENDCG

}}}