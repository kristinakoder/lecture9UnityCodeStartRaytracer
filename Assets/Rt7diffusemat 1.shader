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

		SubShader { Pass {

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
		float4 _colorchooser;

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

		static float rand_seed = 0.0;
		static float2 rand_uv = float2(0.0, 0.0);

		static float rand() 
		{
			float2 noise = frac(sin(dot(float2(rand_uv.x + rand_seed, rand_uv.y + rand_seed), float2(12.9898, 78.233) * 2.0)) * 43758.5453);
			rand_seed += 0.01;
			return abs(noise.x + noise.y) * 0.5;
		}

		vec3 random_in_unit_sphere() 
		{
			vec3 p;
			do {
				p = 2.0 * vec3(rand(), rand(), rand()) - vec3(1.0, 1.0, 1.0);
			} while (dot(p, p) >= 1.0);
				return p;
		}

		struct hit_record 
		{
			float t;
			vec3 position;
			vec3 normal;
		};

		struct ray
		{
			vec3 origin;
			vec3 direction;

			static ray from(vec3 origin, vec3 direction) {
				ray r;
				r.origin = origin;
				r.direction = direction;

				return r;
			}

			vec3 point_at(float t) {
				return origin + t*direction;
			}
		};


		struct camera 
		{
			vec3 origin;
			vec3 horizontal;
			vec3 vertical;
			vec3 lower_left_corner;
				
			ray get_ray(float u, float v) {
					return ray::from(origin, lower_left_corner + u * horizontal + v * vertical);
				}

				static camera create() {
					camera c;

					c.lower_left_corner = vec3(-2, -1, -1);
					c.horizontal = vec3(4.0, 0, 0);
					c.vertical = vec3(0, 2.0, 0);
					c.origin = vec3(0, 0, 0);

					return c;
				}
			};

			struct sphere
			{
				vec3 center;
				float radius;

				static sphere from(vec3 center, float radius) {
					sphere s;
					s.center = center;
					s.radius = radius;

					return s;
				}

				bool intersect(ray r, float t_min, float t_max, out hit_record record) {
					vec3 oc = r.origin - center;
					float a = dot(r.direction, r.direction);
					float b = dot(oc, r.direction);
					float c = dot(oc, oc) - radius*radius;

					float discriminant = b * b - a * c;

					if (discriminant > 0) {
						float solution = (-b - sqrt(discriminant)) / a;
						if (solution < t_max && solution > t_min) {
							record.t = solution;
							record.position = r.point_at(record.t);
							record.normal = (record.position - center) / radius;
							return true;
						}
						solution = (-b + sqrt(discriminant)) / a;
						if (solution < t_max && solution > t_min) {
							record.t = solution;
							record.position = r.point_at(record.t);
							record.normal = (record.position - center) / radius;
							return true;
						}
					}
					return false;
				}
			};

			static const sphere WORLD[2] = {
				{ vec3(0.0, 0.0, -1.0), 0.5 },
				{ vec3(0.0, -100.5, -1.0), 100.0 }
			};

			bool intersect_world(ray r, float t_min, float t_max, out hit_record record) {
				hit_record temp_record;
				bool intersected = false;
				float closest = t_max;

				for (uint i = 0; i < 2; i++) {
					sphere s = WORLD[i];
					if (s.intersect(r, t_min, closest, temp_record)) {
						intersected = true;
						closest = temp_record.t;
						record = temp_record;
					}
				}

				return intersected;
			}

			vec3 background(ray r) {
				float t = 0.5 * (normalize(r.direction).y + 1.0);
				return lerp(vec3(1.0, 1.0, 1.0), vec3(0.5, 0.7, 1.0), t);
			}

			vec3 trace(ray r) {

				vec3 color = vec3(1.0, 1.0, 1.0);

				hit_record record;

				uint i = 0;
				while ((i < _maxbounces) && intersect_world(r, 0.001, 100000.0, record)) {

					vec3 target = record.position + record.normal + random_in_unit_sphere();
					r = ray::from(record.position, target - record.position);

					color *= 0.5;

					i += 1;
				}

				if (i == _maxbounces) {
					return vec3(0.0, 0.0, 0.0);
				}
				else {
					return color * background(r);
				}
			}

			fixed4 frag(v2f i) : SV_Target
			{

				vec3 lower_left_corner = {-2, -1, -1};
				vec3 horizontal = {4, 0, 0};
				vec3 vertical = {0, 2, 0};
				vec3 origin = {0, 0, 0};

				camera cam = camera::create();

				float u = i.uv.x;
				float v = i.uv.y;
				rand_uv = i.uv; // initialize random generator seed.

				col3 col = col3(0.0, 0.0, 0.0);

				for (uint i = 0; i < _raysprpixel; i++) {
					float du = rand() * 0.003;
					float dv = rand() * 0.003;

					ray r = cam.get_ray(u + du, v + dv);
					col += col3(trace(r));
				}

				col /= _raysprpixel;
				col = sqrt(col);

				return fixed4(col, 1.0);
			}
			
			ENDCG
		}
	}
}