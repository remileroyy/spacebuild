#[compute]
#version 460

// #------ SIMPLEX NOISE ------#
// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20201014 (stegu)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
vec3 mod289(vec3 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
	return mod289(((x*34.0)+10.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v)
{ 
	const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
	const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

	// First corner
	vec3 i  = floor(v + dot(v, C.yyy) );
	vec3 x0 =   v - i + dot(i, C.xxx) ;

	// Other corners
	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min( g.xyz, l.zxy );
	vec3 i2 = max( g.xyz, l.zxy );

	//   x0 = x0 - 0.0 + 0.0 * C.xxx;
	//   x1 = x0 - i1  + 1.0 * C.xxx;
	//   x2 = x0 - i2  + 2.0 * C.xxx;
	//   x3 = x0 - 1.0 + 3.0 * C.xxx;
	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
	vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

	// Permutations
	i = mod289(i); 
	vec4 p = permute( permute( permute( 
			i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
			+ i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
			+ i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

	// Gradients: 7x7 points over a square, mapped onto an octahedron.
	// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
	float n_ = 0.142857142857; // 1.0/7.0
	vec3  ns = n_ * D.wyz - D.xzx;

	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

	vec4 x = x_ *ns.x + ns.yyyy;
	vec4 y = y_ *ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);

	vec4 b0 = vec4( x.xy, y.xy );
	vec4 b1 = vec4( x.zw, y.zw );

	vec4 s0 = floor(b0)*2.0 + 1.0;
	vec4 s1 = floor(b1)*2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));

	vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
	vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

	vec3 p0 = vec3(a0.xy,h.x);
	vec3 p1 = vec3(a0.zw,h.y);
	vec3 p2 = vec3(a1.xy,h.z);
	vec3 p3 = vec3(a1.zw,h.w);

	//Normalise gradients
	vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	// Mix final noise value
	vec4 m = max(0.5 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
	m = m * m;
	return 105.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

struct Triangle {
	vec4 a;
	vec4 b;
	vec4 c;
	vec4 norm;
};

// #------ Marching Cubes ------#
const int cornerIndexAFromEdge[12] = {0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3};
const int cornerIndexBFromEdge[12] = {1, 2, 3, 0, 5, 6, 7, 4, 4, 5, 6, 7};

const int offsets[256] = {0, 0, 3, 6, 12, 15, 21, 27, 36, 39, 45, 51, 60, 66, 75, 84, 90, 93, 99, 105, 114, 120, 129, 138, 150, 156, 165, 174, 186, 195, 207, 219, 228, 231, 237, 243, 252, 258, 267, 276, 288, 294, 303, 312, 324, 333, 345, 357, 366, 372, 381, 390, 396, 405, 417, 429, 438, 447, 459, 471, 480, 492, 507, 522, 528, 531, 537, 543, 552, 558, 567, 576, 588, 594, 603, 612, 624, 633, 645, 657, 666, 672, 681, 690, 702, 711, 723, 735, 750, 759, 771, 783, 798, 810, 825, 840, 852, 858, 867, 876, 888, 897, 909, 915, 924, 933, 945, 957, 972, 984, 999, 1008, 1014, 1023, 1035, 1047, 1056, 1068, 1083, 1092, 1098, 1110, 1125, 1140, 1152, 1167, 1173, 1185, 1188, 1191, 1197, 1203, 1212, 1218, 1227, 1236, 1248, 1254, 1263, 1272, 1284, 1293, 1305, 1317, 1326, 1332, 1341, 1350, 1362, 1371, 1383, 1395, 1410, 1419, 1425, 1437, 1446, 1458, 1467, 1482, 1488, 1494, 1503, 1512, 1524, 1533, 1545, 1557, 1572, 1581, 1593, 1605, 1620, 1632, 1647, 1662, 1674, 1683, 1695, 1707, 1716, 1728, 1743, 1758, 1770, 1782, 1791, 1806, 1812, 1827, 1839, 1845, 1848, 1854, 1863, 1872, 1884, 1893, 1905, 1917, 1932, 1941, 1953, 1965, 1980, 1986, 1995, 2004, 2010, 2019, 2031, 2043, 2058, 2070, 2085, 2100, 2106, 2118, 2127, 2142, 2154, 2163, 2169, 2181, 2184, 2193, 2205, 2217, 2232, 2244, 2259, 2268, 2280, 2292, 2307, 2322, 2328, 2337, 2349, 2355, 2358, 2364, 2373, 2382, 2388, 2397, 2409, 2415, 2418, 2427, 2433, 2445, 2448, 2454, 2457, 2460};
const int lengths[256] = {0, 3, 3, 6, 3, 6, 6, 9, 3, 6, 6, 9, 6, 9, 9, 6, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 6, 9, 9, 6, 9, 12, 12, 9, 9, 12, 12, 9, 12, 15, 15, 6, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 6, 9, 9, 12, 9, 12, 12, 15, 9, 12, 12, 15, 12, 15, 15, 12, 6, 9, 9, 12, 9, 12, 6, 9, 9, 12, 12, 15, 12, 15, 9, 6, 9, 12, 12, 9, 12, 15, 9, 6, 12, 15, 15, 12, 15, 6, 12, 3, 3, 6, 6, 9, 6, 9, 9, 12, 6, 9, 9, 12, 9, 12, 12, 9, 6, 9, 9, 12, 9, 12, 12, 15, 9, 6, 12, 9, 12, 9, 15, 6, 6, 9, 9, 12, 9, 12, 12, 15, 9, 12, 12, 15, 12, 15, 15, 12, 9, 12, 12, 9, 12, 15, 15, 12, 12, 9, 15, 6, 15, 12, 6, 3, 6, 9, 9, 12, 9, 12, 12, 15, 9, 12, 12, 15, 6, 9, 9, 6, 9, 12, 12, 15, 12, 15, 15, 6, 12, 9, 15, 12, 9, 6, 12, 3, 9, 12, 12, 15, 12, 15, 9, 12, 12, 15, 15, 6, 9, 12, 6, 3, 6, 9, 9, 6, 9, 12, 6, 3, 9, 6, 12, 3, 6, 3, 3, 0};


layout(set = 0, binding = 0, std430) restrict buffer TriangleBuffer
{
	Triangle triangles[];
};

layout(set = 0, binding = 1, std430) restrict buffer VoxelBuffer
{
	float voxels[];
};

layout(set = 0, binding = 2, std430) restrict buffer ParamsBuffer
{
	float size;
	float posX;
	float posY;
	float posZ;
	float digR;
};

layout(set = 0, binding = 3, std430) coherent buffer Counter
{
	uint counter;
};

layout(set = 0, binding = 4, std430) restrict buffer LutBuffer
{
	int lut[];
};

float noiseAt(vec3 samplePos)
{
	float sum = 0;
	float amplitude = 1;
	float weight = 1;
	
	for (int i = 0; i < 6; i ++)
	{
		float noise = snoise(samplePos) * 2 - 1;
		noise = 1 - abs(noise);
		noise *= noise;
		noise *= weight;
		weight = max(0, min(1, noise * 10));
		sum += noise * amplitude;
		samplePos *= 2;
		amplitude *= 0.5;
	}
	return 0.5 * sum;
}

const float scale = 0.0037;
const vec3 offset = vec3(547.622, 145.795, 378.446);

vec4 evaluate(vec3 coord)
{   
	vec3 worldPos = vec3(posX, posY, posZ) + coord;
	int index = int(worldPos.x + (size + 1.0) * (worldPos.y + (size + 1.0) * worldPos.z));
	if (voxels[index] == 0)
	{
		vec3 samplePos = worldPos * scale + offset;
		float dist = length(worldPos - vec3(0.5 * size));
		voxels[index] = 0.5 + 0.5 * noiseAt(samplePos) - 2.5 * dist/size;
	}
	return vec4(coord, voxels[index]);
}

vec4 interpolateVerts(vec4 v1, vec4 v2, float isoLevel)
{
	//return (v1 + v2) * 0.5;
	float t = (isoLevel - v1.w) / (v2.w - v1.w);
	return v1 + t * (v2 - v1);
}


layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;
void main()
{
	vec3 id = gl_GlobalInvocationID;


	// Dig
	if (digR > 0.1)
	{
		vec3 zonePos = vec3(floor(posX) - 2, floor(posY) - 2, floor(posZ) - 2);
		vec3 coord = zonePos + id;

		if ((coord.x >= 0.0) && (coord.x <= size) && (coord.y >= 0.0) && (coord.y <= size) && (coord.z >= 0.0) && (coord.z <= size))
		{
			int index = int(coord.x + (size + 1.0) * (coord.y + (size + 1.0) * coord.z));
			vec3 digPos = vec3(posX, posY, posZ);
			float dist = distance(coord, digPos);
			if (dist < digR)
			{
				voxels[index] -= digR - dist;
			}
		}
	}


	// Marching Cube
	else
	{
		// 8 corners of the current cube
		vec4 cubeCorners[8] = {
			evaluate(vec3(id.x + 0, id.y + 0, id.z + 0)),
			evaluate(vec3(id.x + 1, id.y + 0, id.z + 0)),
			evaluate(vec3(id.x + 1, id.y + 0, id.z + 1)),
			evaluate(vec3(id.x + 0, id.y + 0, id.z + 1)),
			evaluate(vec3(id.x + 0, id.y + 1, id.z + 0)),
			evaluate(vec3(id.x + 1, id.y + 1, id.z + 0)),
			evaluate(vec3(id.x + 1, id.y + 1, id.z + 1)),
			evaluate(vec3(id.x + 0, id.y + 1, id.z + 1))
		};

		// Calculate unique index for each cube configuration.
		// There are 256 possible values
		// A value of 0 means cube is entirely inside surface; 255 entirely outside.
		// The value is used to look up the edge table, which indicates which edges of the cube are cut by the isosurface.
		uint cubeIndex = 0;
		float isoLevel = 0.0;
		if (cubeCorners[0].w < isoLevel) cubeIndex |= 1;
		if (cubeCorners[1].w < isoLevel) cubeIndex |= 2;
		if (cubeCorners[2].w < isoLevel) cubeIndex |= 4;
		if (cubeCorners[3].w < isoLevel) cubeIndex |= 8;
		if (cubeCorners[4].w < isoLevel) cubeIndex |= 16;
		if (cubeCorners[5].w < isoLevel) cubeIndex |= 32;
		if (cubeCorners[6].w < isoLevel) cubeIndex |= 64;
		if (cubeCorners[7].w < isoLevel) cubeIndex |= 128;

		// Create triangles for current cube configuration
		int numIndices = lengths[cubeIndex];
		int offset = offsets[cubeIndex];
		
		for (int i = 0; i < numIndices; i += 3) {
			// Get indices of corner points A and B for each of the three edges
			// of the cube that need to be joined to form the triangle.
			int v0 = lut[offset + i];
			int v1 = lut[offset + 1 + i];
			int v2 = lut[offset + 2 + i];

			int a0 = cornerIndexAFromEdge[v0];
			int b0 = cornerIndexBFromEdge[v0];

			int a1 = cornerIndexAFromEdge[v1];
			int b1 = cornerIndexBFromEdge[v1];

			int a2 = cornerIndexAFromEdge[v2];
			int b2 = cornerIndexBFromEdge[v2];

			
			// Calculate vertex positions
			Triangle currTri;
			currTri.a = interpolateVerts(cubeCorners[a0], cubeCorners[b0], isoLevel);
			currTri.b = interpolateVerts(cubeCorners[a1], cubeCorners[b1], isoLevel);
			currTri.c = interpolateVerts(cubeCorners[a2], cubeCorners[b2], isoLevel);

			vec3 ab = currTri.b.xyz - currTri.a.xyz;
			vec3 ac = currTri.c.xyz - currTri.a.xyz;
			currTri.norm = -vec4(normalize(cross(ab,ac)), 0);

			uint index = atomicAdd(counter, 1u);
			triangles[index] = currTri;
		}
	}
}