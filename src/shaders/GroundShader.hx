package shaders;

class GroundShader extends hxsl.Shader {
	static var SRC = {
		@global var camera : {
			var view : Mat4;
			var proj : Mat4;
			var position : Vec3;
			var projDiag : Vec3;
			var viewProj : Mat4;
			var inverseViewProj : Mat4;
			var zNear : Float;
			var zFar : Float;
			@var var dir : Vec3;
		};

		@global var global : {
			var time : Float;
			var pixelSize : Vec2;
			@perObject var modelView : Mat4;
			@perObject var modelViewInverse : Mat4;
		};

		@input var input : {
			var position : Vec3;
			var normal : Vec3;
			var uv : Vec2;
		};

		var output : {
			var position : Vec4;
			var color : Vec4;
			var depth : Vec4;
			var normal : Vec4;
		};

		var relativePosition : Vec3;
		var transformedPosition : Vec3;
		var pixelTransformedPosition : Vec3;
		var transformedNormal : Vec3;
		var projectedPosition : Vec4;
		var pixelColor : Vec4;
		var depth : Float;
		var screenUV : Vec2;
		var specPower : Float;
		var specColor : Vec3;
		var textureColor : Vec4;
		var uv : Vec2;

		@param var color : Vec4;
		@param var diffuse : Sampler2D;
		@param var specularPower : Float;
		@param var specularAmount : Float;
		@param var specularColor : Vec3;

		// each __init__ expr is out of order dependency-based
		function __init__() {
			relativePosition = input.position;
			transformedPosition = relativePosition * global.modelView.mat3x4();
			projectedPosition = vec4(transformedPosition, 1) * camera.viewProj;
			transformedNormal = (input.normal * global.modelView.mat3()).normalize();
			camera.dir = (camera.position - transformedPosition).normalize();
			pixelColor = color;
			specPower = specularPower;
			specColor = specularColor * specularAmount;
			screenUV = (projectedPosition.xy / projectedPosition.w) * vec2(0.5, -0.5) + 0.5;
			depth = projectedPosition.z / projectedPosition.w;
			uv = vec2(input.uv.x, input.uv.y * 0.2 + (global.time / 5) % 0.8);
		}

		function __init__fragment() {
			transformedNormal = transformedNormal.normalize();
			// same as __init__, but will force calculus inside fragment shader, which limits varyings
			screenUV = (projectedPosition.xy / projectedPosition.w) * vec2(0.5, -0.5) + 0.5;
			depth = projectedPosition.z / projectedPosition.w; // in case it's used in vertex : we don't want to interpolate in screen space
			specPower = specularPower;
			specColor = specularColor * specularAmount;
			textureColor = diffuse.get(uv);
		}

		function vertex() {
			output.position = projectedPosition;
			pixelTransformedPosition = transformedPosition;
		}

		function fragment() {
			output.color = pixelColor;
			output.color *= textureColor;
			output.depth = pack(depth);
			output.normal = packNormal(transformedNormal);
		}

	};

	public function new() {
		super();
		color.set(1, 1, 1);
		specularColor.set(1, 1, 1);
		specularPower = 50;
		specularAmount = 1;
	}

}
