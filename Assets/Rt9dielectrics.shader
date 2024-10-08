﻿﻿Shader "Unlit/SingleColor"
{
	Properties
	{
	_refractionIndex("Refraction Index", Range(0,3)) = 1
	_maxbounces("max bounses", Range(1,100)) = 10
	_raysprpixel("Rays per pixel", Range(1,1000)) = 300
	}

		SubShader{ Pass	{
			
	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

	float _raysprpixel;
	float _refractionIndex;
	float _maxbounces;

	typedef vector <float, 3> vec3;
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

	float2 random_seed = float2(0.0, 0.0);
	float random_incr = 0.0;
	
	float rand()
	{
		float2 noise = (frac(sin(dot(float2(random_seed.x+random_incr,random_seed.y+random_incr), float2(12.9898, 78.233)*2.0)) * 43758.5453));
		random_incr += 0.01; 
		return abs(noise.x + noise.y) * 0.5;
	}

	vec3 random_in_sphere()
	{
		vec3 v = 2.0 * vec3(rand(), rand(), rand()) - vec3(1.0, 1.0, 1.0);
		v = normalize(v);
		return v * rand();
	}

	class ray
	{
		void make(vec3 orig, vec3 dir) { _origin = orig; _direction = dir; }
		vec3 at(float t) { return _origin + _direction*t; }
		vec3 _origin;
		vec3 _direction;
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
		float mat;
		vec3 matproperties;
		float fuzz;
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
			rec.mat = materialtype;
			rec.matproperties = matproperties;
			rec.fuzz = fuzz;
	
			return true;
		}
		vec3 center;
		float radius;
		float materialtype;
		vec3 matproperties;
		float fuzz;
	};

	void getsphere(int i, out sphere sph)
	{
		if (i == 0) { sph.center = vec3( 0, 0, -1); sph.radius = 0.5; sph.materialtype = 0; sph.matproperties.xyz = vec3(0.1, 0.2, 0.5); sph.fuzz = 1.5;}
		if (i == 1) { sph.center = vec3( 0,-100.5, -1); sph.radius = 100; sph.materialtype = 0; sph.matproperties.xyz = vec3(0.8, 0.8, 0.0); sph.fuzz = 0;}
		if (i == 2) { sph.center = vec3( 1, 0, -1); sph.radius = 0.5; sph.materialtype = 1; sph.matproperties.xyz = vec3(0.8, 0.6, 0.2); sph.fuzz = 0.0;}
		if (i == 3) { sph.center = vec3(-1, 0, -1); sph.radius = 0.5; sph.materialtype = 2; sph.matproperties.xyz = vec3(1.0, 1.0, 1.0); sph.fuzz = 1.5;}
		if (i == 4) { sph.center = vec3(-1, 0, -1); sph.radius = -0.4; sph.materialtype = 2; sph.matproperties.xyz = vec3(1.0, 1.0, 1.0); sph.fuzz = 1.5;}
	}

	bool world_hit(ray r, float min, float max, out hit_record rec)
	{
		hit_record temp_rec = (hit_record) 0;
		bool found_hit = false;
		float closest_so_far = max;

		for (int i = 0; i < 5; i++)
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

	vec3 refract(vec3 uv, vec3 n, float etai_over_etat)
	{
		float cos_theta = min(dot(-uv, n), 1.0);
		vec3 r_out_perp = etai_over_etat * (uv + cos_theta * n);
		vec3 r_out_parallel = -sqrt(abs(1.0 - length(r_out_perp) * length(r_out_perp)))*n;
		return r_out_perp + r_out_parallel;
	}

	float reflectance(float cosine, float ref_idx)
	{
		float r0 = (1-ref_idx) / (1+ref_idx);
		r0 = r0*r0;
		return r0 + (1-r0)*pow((1 - cosine), 5);
	}

	bool scatter(ray r, hit_record rec, out ray scattered)
	{
		if (rec.mat == 0)
		{
			scattered.make(rec.p, rec.normal + random_in_sphere());
			return true;
		}
		if (rec.mat == 1)
		{
			vec3 reflected = reflect(normalize(r._direction), rec.normal);
			scattered.make(rec.p, reflected + rec.fuzz * random_in_sphere());
			return (dot(scattered._direction, rec.normal) > 0);
		}
		else
		{
			float refraction_ratio = rec.front_face ? (1.0/_refractionIndex) : _refractionIndex;
			vec3 unit_direction = normalize(r._direction);
			float cos_theta = min(dot(-unit_direction, rec.normal), 1.0);
			float sin_theta = sqrt(1.0 - cos_theta*cos_theta);

			bool cannot_refract = refraction_ratio * sin_theta > 1.0;
			vec3 direction;

			if (cannot_refract || reflectance(cos_theta, refraction_ratio) > rand())
				direction = reflect(unit_direction, rec.normal);
			else
				direction = refract(unit_direction, rec.normal, refraction_ratio);

			scattered.make(rec.p, direction);
			return true;
		}
	}

	col3 ray_color(ray r)
	{
		hit_record rec = (hit_record) 0;
		col3 accumCol = {1,1,1};
		int i = _maxbounces;

		while (world_hit(r, 0.001, 1000000, rec) && i > 0)
		{
			ray scattered;
			scatter(r, rec, scattered);
			
			accumCol *= rec.matproperties;
			r = scattered;

			i--;
		}
			
		if (i == 0)
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
		for (int j = 0; j < _raysprpixel; j++)
		{
			r.make(origin, lower_left_corner + (x + 0.003 * rand()) * horizontal + (y + 0.003 * rand()) * vertical);
			col += ray_color(r);
		}
		col /= _raysprpixel;
		
		col = sqrt(col);
		return fixed4(col,1); 
	}

ENDCG

}}}