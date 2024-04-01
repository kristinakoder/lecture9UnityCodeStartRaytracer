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

	col3 ray_color(ray r)
	{
		vec3 unitDirection = r._direction / length(r._direction);
		float a = 0.5*(unitDirection.y + 1.0);
		return (1.0-a)*col3(1.0,1.0,1.0) + a*col3(0.5,0.7,1.0);
	}

	float length(vec3 v)
	{
		return sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
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