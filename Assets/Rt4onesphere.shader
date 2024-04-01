Shader "Unlit/SingleColor"
{
		SubShader{ Pass	{
			
	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

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
			front_face = dot(r._direction, outward_normal);
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

		vec3 center;
		float radius;
		float materialtype;
		vec3 matproperties;
	};

	float hit_sphere(vec3 center, float radius, ray r)
	{
		vec3 oc = r._origin - center;
		float a = dot(r._direction, r._direction);
		float b = 2.0 * dot(oc, r._direction);
		float c = dot(oc, oc) - radius*radius;
		float discriminant = b*b - 4*a*c;
		if (discriminant < 0) return -1.0;
		else return (-b - sqrt(discriminant)) / (2.0*a);
	}	

	col3 ray_color(ray r)
	{
		float t = hit_sphere(vec3(0,0,-1), 0.5, r);
		if (t > 0.0) 
		{
			vec3 N = normalize(r.at(t) - vec3(0,0,-1));
			return 0.5*col3(N.x+1, N.y+1, N.z+1);
		}
		vec3 unitDirection = normalize(r._direction);
		float a = 0.5*(unitDirection.y + 1.0);
		return (1.0-a)*col3(1.0,1.0,1.0) + a*col3(0.5,0.7,1.0);
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
		r.make(origin, lower_left_corner + x*horizontal + y*vertical);
		col3 col = ray_color(r);

		return fixed4(col,1); 
	}

ENDCG

}}}