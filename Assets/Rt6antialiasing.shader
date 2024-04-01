Shader "Unlit/SingleColor"
{
	Properties
	{
	_raysprpixel("Rays per pixel", Range(10,1000)) = 1
	}

		SubShader{ Pass	{
			
	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

	float _raysprpixel;

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
	
	float rand(in float2 uv)
	{
		float2 noise = (frac(sin(dot(uv, float2(12.9898, 78.233)*2.0)) * 43758.5453));
		return abs(noise.x + noise.y) * 0.5;
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
	};

	class sphere
	{
		void make(vec3 c, float r) {center = c; radius = r;}
		
		bool hit(ray r, float ray_tmin, float ray_tmax, out hit_record rec)
		{
			vec3 oc = r._origin - center;
			float a = dot(r._direction, r._direction);
			float half_b = dot(oc, r._direction);
			float c = dot(oc,oc) - radius * radius;

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

	col3 ray_color(ray r)
	{
		for (int i = 0; i < 2; i++)
		{
			hit_record rec = (hit_record) 0;

			sphere s;
			getsphere(i, s);

			if (s.hit(r, 0.001, 1000000, rec)) 
				return 0.5 * (rec.normal + col3(1,1,1));		
		}
		
		vec3 unit_direction = normalize(r._direction);
		float y = 0.5*(unit_direction.y + 1.0); 
		return (1.0-y)*col3(1.0,1.0,1.0) + y*col3(0.5,0.7,1.0);
	}

	fixed4 frag(v2f i) : SV_Target 
	{
		vec3 lower_left_corner = {-2, -1, -1};
		vec3 horizontal = {4, 0, 0};
		vec3 vertical = {0, 2, 0};
		vec3 origin = {0, 0, 0};

		float x = i.uv.x;
		float y = i.uv.y;
		
		ray r;
		col3 col = {0,0,0};
		for (int i = 0; i < _raysprpixel; i++)
		{
			float xrand = rand((x+i, y-i)) * 0.005;
			float yrand = rand((y+i, x-i)) * 0.005;
			r.make(origin, lower_left_corner + (xrand+x)*horizontal + (yrand+y)*vertical);
			col += ray_color(r);
		}
		col /= _raysprpixel;
		return fixed4(col,1); 
	}

ENDCG

}}}