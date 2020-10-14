part of askr;

class _Particle {
  Vector2 pos;
  Vector2 startPos;

  double colorPos = 0.0;
  double deltaColorPos = 0.0;

  double size = 0.0;
  double deltaSize = 0.0;

  double rotation = 0.0;
  double deltaRotation = 0.0;

  double timeToLive = 0.0;

  Vector2 dir;

  _ParticleAccelerations accelerations;

  Float64List simpleColorSequence;

  ColorSequence colorSequence;
}

class _ParticleAccelerations {
  double radialAccel = 0.0;
  double tangentialAccel = 0.0;
}

/// 粒子系统使用大量的精灵绘制复杂的效果，例如爆炸，烟雾，雨水或火
/// 可以设置许多属性来控制粒子系统的外观
/// 大多数属性都有一个基本值和一个方差，在创建每个单独的粒子时会使用这些值
/// 例如，通过将[life]设置为1.0并将[lifeVar]设置为0.5，每个粒子的寿命将在0.5到1.5之间
/// 在[emissionRate]中创建了粒子并将其添加到系统中，但是粒子的数量绝不能超过[maxParticles]限制
class ParticleSystem extends Node {
  /// 创建具有给定属性的新粒子系统
  /// 唯一需要的参数是纹理，所有其他参数都是可选的
  ParticleSystem(
    this.texture, {
    this.life: 1.5,
    this.lifeVar: 1.0,
    this.posVar: Offset.zero,
    this.startSize: 2.5,
    this.startSizeVar: 0.5,
    this.endSize: 0.0,
    this.endSizeVar: 0.0,
    this.startRotation: 0.0,
    this.startRotationVar: 0.0,
    this.endRotation: 0.0,
    this.endRotationVar: 0.0,
    this.rotateToMovement: false,
    this.direction: 0.0,
    this.directionVar: 360.0,
    this.speed: 100.0,
    this.speedVar: 50.0,
    this.radialAcceleration: 0.0,
    this.radialAccelerationVar: 0.0,
    this.tangentialAcceleration: 0.0,
    this.tangentialAccelerationVar: 0.0,
    this.maxParticles: 100,
    this.emissionRate: 50.0,
    this.colorSequence,
    this.alphaVar: 0,
    this.redVar: 0,
    this.greenVar: 0,
    this.blueVar: 0,
    this.transferMode: BlendMode.plus,
    this.numParticlesToEmit: 0,
    this.autoRemoveOnFinish: true,
    Offset gravity,
    String data,
    BlendMode blendMode,
  }) {
    this.gravity = gravity;
    _particles = new List<_Particle>();
    _emitCounter = 0.0;
    // _elapsedTime = 0.0;
    if (_gravity == null) _gravity = new Vector2.zero();
    if (colorSequence == null)
      colorSequence = new ColorSequence.fromStartAndEndColor(
          new Color(0xffffffff), new Color(0x00ffffff));

    insertionOffset = Offset.zero;

    if (data != null) {
      deserializeParticleSystem(json.decode(data), particleSystem: this);
    }
  }

  /// 用于绘制每个单独的精灵的纹理
  SpriteTexture texture;

  /// 每个粒子存活的时间（以秒为单位)
  double life;

  /// [life] 属性的方差
  double lifeVar;

  /// 粒子初始位置的方差
  Offset posVar;

  /// 每个粒子的起始比例
  double startSize;

  /// [startSize] 属性的方差
  double startSizeVar;

  /// 每个粒子的最终比例
  double endSize;

  /// [endSize] 属性的方差
  double endSizeVar;

  /// 每个粒子的开始旋转
  double startRotation;

  /// [startRotation] 属性的方差
  double startRotationVar;

  /// 每个粒子的结束旋转
  double endRotation;

  /// [endRotation] 属性的方差
  double endRotationVar;

  /// If true, each particle will be rotated to the direction of the movement
  /// of the particle. The calculated rotation will be added to the current
  /// rotation as calculated by the [startRotation] and [endRotation]
  /// properties.
  /// 如果为true，则每个粒子将旋转到运动方向粒子的
  /// 计算出的旋转将添加到由 [startRotation] 和 [endRotation] 属性计算出的当前旋转中
  bool rotateToMovement;

  /// 每个粒子的发射方向，以度为单位
  double direction;

  /// [direction] 属性的方差
  double directionVar;

  /// 每个粒子的发射速度
  double speed;

  /// [direction] 属性的方差
  double speedVar;

  /// 每个粒子的径向加速度
  double radialAcceleration;

  /// [radialAcceleration] 属性的方差
  double radialAccelerationVar;

  /// 每个粒子的切向加速度
  double tangentialAcceleration;

  /// [tangentialAcceleration] 属性的方差
  double tangentialAccelerationVar;

  /// 粒子系统的重力向量
  Offset get gravity {
    if (_gravity == null) return null;

    return new Offset(_gravity.x, _gravity.y);
  }

  Vector2 _gravity;

  set gravity(Offset gravity) {
    if (gravity == null)
      _gravity = null;
    else
      _gravity = new Vector2(gravity.dx, gravity.dy);
  }

  /// The maximum number of particles the system can display at a single time.
  int maxParticles;

  /// Total number of particles to emit, if the value is set to 0 the system
  /// will continue to emit particles for an indifinte period of time.
  int numParticlesToEmit;

  /// The rate at which particles are emitted, defined in particles per second.
  double emissionRate;

  /// If set to true, the particle system will be automatically removed as soon
  /// as there are no more particles left to draw.
  bool autoRemoveOnFinish;

  /// The [ColorSequence] used to animate the color of each individual particle
  /// over the duration of its [life]. When applied to a particle the sequence's
  /// color stops modified in accordance with the [alphaVar], [redVar],
  /// [greenVar], and [blueVar] properties.
  ColorSequence colorSequence;

  /// Alpha varience of the [colorSequence] property.
  int alphaVar;

  /// Red varience of the [colorSequence] property.
  int redVar;

  /// Green varience of the [colorSequence] property.
  int greenVar;

  /// Blue varience of the [colorSequence] property.
  int blueVar;

  /// The transfer mode used to draw the particle system. Default is
  /// [BlendMode.plus].
  BlendMode transferMode;

  List<_Particle> _particles;

  double _emitCounter;
  int _numEmittedParticles = 0;

  /// The over all opacity of the particle system. This value is multiplied by
  /// the opacity of the individual particles.
  double opacity = 1.0;

  /// Offset of where the particles are inserted, this is useful for doing
  /// particle systems where the source of the particles move (e.g. smoke
  /// trailing a rocket).
  Offset insertionOffset;

  static Paint _paint = new Paint()
    ..filterQuality = FilterQuality.low
    ..isAntiAlias = false;

  void reset() {
    _numEmittedParticles = 0;
    _particles.clear();
  }

  @override
  void update(double dt) {
    // TODO: Fix this (it's a temp fix for low framerates)
    if (dt > 0.1) dt = 0.1;

    // Create new particles
    double rate = 1.0 / emissionRate;

    if (_particles.length < maxParticles) {
      _emitCounter += dt;
    }

    while (_particles.length < maxParticles &&
        _emitCounter > rate &&
        (numParticlesToEmit == 0 ||
            _numEmittedParticles < numParticlesToEmit)) {
      // Add a new particle
      _addParticle();
      _emitCounter -= rate;
    }

    // _elapsedTime += dt;

    // Iterate over all particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      _Particle particle = _particles[i];

      // Manage life time
      particle.timeToLive -= dt;
      if (particle.timeToLive <= 0) {
        _particles.removeAt(i);
        continue;
      }

      // Update the particle

      if (particle.accelerations != null) {
        // Radial acceleration
        Vector2 radial;
        if (particle.pos[0] != 0 || particle.pos[1] != 0) {
          radial = new Vector2.copy(particle.pos)..normalize();
        } else {
          radial = new Vector2.zero();
        }
        Vector2 tangential = new Vector2.copy(radial);
        radial.scale(particle.accelerations.radialAccel);

        // Tangential acceleration
        double newY = tangential.x;
        tangential.x = -tangential.y;
        tangential.y = newY;
        tangential.scale(particle.accelerations.tangentialAccel);

        // (gravity + radial + tangential) * dt
        final Vector2 accel = (_gravity + radial + tangential)..scale(dt);
        particle.dir += accel;
      } else if (_gravity[0] != 0.0 || _gravity[1] != 0) {
        // gravity
        final Vector2 accel = _gravity.clone()..scale(dt);
        particle.dir += accel;
      }

      // Update particle position
      particle.pos[0] += particle.dir[0] * dt;
      particle.pos[1] += particle.dir[1] * dt;

      // Size
      particle.size = math.max(particle.size + particle.deltaSize * dt, 0.0);

      // Angle
      particle.rotation += particle.deltaRotation * dt;

      // Color
      if (particle.simpleColorSequence != null) {
        for (int i = 0; i < 4; i++) {
          particle.simpleColorSequence[i] +=
              particle.simpleColorSequence[i + 4] * dt;
        }
      } else {
        particle.colorPos =
            math.min(particle.colorPos + particle.deltaColorPos * dt, 1.0);
      }
    }

    if (autoRemoveOnFinish &&
        _particles.length == 0 &&
        _numEmittedParticles > 0) {
      if (parent != null) removeFromParent();
    }
  }

  void _addParticle() {
    _Particle particle = new _Particle();

    // Time to live
    particle.timeToLive = math.max(life + lifeVar * randomSignedDouble(), 0.0);

    // Position
    Offset srcPos = insertionOffset;
    particle.pos = new Vector2(srcPos.dx + posVar.dx * randomSignedDouble(),
        srcPos.dy + posVar.dy * randomSignedDouble());

    // Size
    particle.size =
        math.max(startSize + startSizeVar * randomSignedDouble(), 0.0);
    double endSizeFinal =
        math.max(endSize + endSizeVar * randomSignedDouble(), 0.0);
    particle.deltaSize = (endSizeFinal - particle.size) / particle.timeToLive;

    // Rotation
    particle.rotation = startRotation + startRotationVar * randomSignedDouble();
    double endRotationFinal =
        endRotation + endRotationVar * randomSignedDouble();
    particle.deltaRotation =
        (endRotationFinal - particle.rotation) / particle.timeToLive;

    // Direction
    double dirRadians =
        convertDegrees2Radians(direction + directionVar * randomSignedDouble());
    Vector2 dirVector = new Vector2(math.cos(dirRadians), math.sin(dirRadians));
    double speedFinal = speed + speedVar * randomSignedDouble();
    particle.dir = dirVector..scale(speedFinal);

    // Accelerations
    if (radialAcceleration != 0.0 ||
        radialAccelerationVar != 0.0 ||
        tangentialAcceleration != 0.0 ||
        tangentialAccelerationVar != 0.0) {
      particle.accelerations = new _ParticleAccelerations();

      // Radial acceleration
      particle.accelerations.radialAccel =
          radialAcceleration + radialAccelerationVar * randomSignedDouble();

      // Tangential acceleration
      particle.accelerations.tangentialAccel = tangentialAcceleration +
          tangentialAccelerationVar * randomSignedDouble();
    }

    // Color
    particle.colorPos = 0.0;
    particle.deltaColorPos = 1.0 / particle.timeToLive;

    if (alphaVar != 0 || redVar != 0 || greenVar != 0 || blueVar != 0) {
      particle.colorSequence = _ColorSequenceUtil.copyWithVariance(
          colorSequence, alphaVar, redVar, greenVar, blueVar);
    }

    // Optimizes the case where there are only two colors in the sequence
    if (colorSequence.colors.length == 2) {
      Color startColor;
      Color endColor;

      if (particle.colorSequence != null) {
        startColor = particle.colorSequence.colors[0];
        endColor = particle.colorSequence.colors[1];
      } else {
        startColor = colorSequence.colors[0];
        endColor = colorSequence.colors[1];
      }

      // First 4 elements are start ARGB, last 4 are delta ARGB
      particle.simpleColorSequence = new Float64List(8);
      particle.simpleColorSequence[0] = startColor.alpha.toDouble();
      particle.simpleColorSequence[1] = startColor.red.toDouble();
      particle.simpleColorSequence[2] = startColor.green.toDouble();
      particle.simpleColorSequence[3] = startColor.blue.toDouble();

      particle.simpleColorSequence[4] =
          (endColor.alpha.toDouble() - startColor.alpha.toDouble()) /
              particle.timeToLive;
      particle.simpleColorSequence[5] =
          (endColor.red.toDouble() - startColor.red.toDouble()) /
              particle.timeToLive;
      particle.simpleColorSequence[6] =
          (endColor.green.toDouble() - startColor.green.toDouble()) /
              particle.timeToLive;
      particle.simpleColorSequence[7] =
          (endColor.blue.toDouble() - startColor.blue.toDouble()) /
              particle.timeToLive;
    }

    _particles.add(particle);
    _numEmittedParticles++;
  }

  @override
  void paint(Canvas canvas) {
    if (opacity == 0.0) return;

    List<RSTransform> transforms = <RSTransform>[];
    List<Rect> rects = <Rect>[];
    List<Color> colors = <Color>[];

    _paint.blendMode = transferMode;

    for (_Particle particle in _particles) {
      // Rect
      Rect rect = texture.frame;
      rects.add(rect);

      // Transform
      double scos;
      double ssin;
      if (rotateToMovement) {
        double extraRotation = GameMath.atan2(particle.dir[1], particle.dir[0]);
        scos = math.cos(
                convertDegrees2Radians(particle.rotation) + extraRotation) *
            particle.size;
        ssin = math.sin(
                convertDegrees2Radians(particle.rotation) + extraRotation) *
            particle.size;
      } else if (particle.rotation != 0.0) {
        scos =
            math.cos(convertDegrees2Radians(particle.rotation)) * particle.size;
        ssin =
            math.sin(convertDegrees2Radians(particle.rotation)) * particle.size;
      } else {
        scos = particle.size;
        ssin = 0.0;
      }
      double ax = rect.width / 2;
      double ay = rect.height / 2;
      double tx = particle.pos[0] + -scos * ax + ssin * ay;
      double ty = particle.pos[1] + -ssin * ax - scos * ay;
      RSTransform transform = new RSTransform(scos, ssin, tx, ty);
      transforms.add(transform);

      // Color
      if (particle.simpleColorSequence != null) {
        Color particleColor = new Color.fromARGB(
            (particle.simpleColorSequence[0] * opacity).toInt().clamp(0, 255),
            particle.simpleColorSequence[1].toInt().clamp(0, 255),
            particle.simpleColorSequence[2].toInt().clamp(0, 255),
            particle.simpleColorSequence[3].toInt().clamp(0, 255));
        colors.add(particleColor);
      } else {
        Color particleColor;
        if (particle.colorSequence != null) {
          particleColor =
              particle.colorSequence.colorAtPosition(particle.colorPos);
        } else {
          particleColor = colorSequence.colorAtPosition(particle.colorPos);
        }
        if (opacity != 1.0) {
          particleColor = particleColor
              .withAlpha((particleColor.alpha * opacity).toInt().clamp(0, 255));
        }
        colors.add(particleColor);
      }
    }

    canvas.drawAtlas(texture.image, transforms, rects, colors,
        BlendMode.modulate, null, _paint);
  }
}

class _ColorSequenceUtil {
  static ColorSequence copyWithVariance(ColorSequence sequence, int alphaVar,
      int redVar, int greenVar, int blueVar) {
    ColorSequence copy = new ColorSequence.copy(sequence);

    int i = 0;
    for (Color color in sequence.colors) {
      int aDelta = ((randomDouble() * 2.0 - 1.0) * alphaVar).toInt();
      int rDelta = ((randomDouble() * 2.0 - 1.0) * redVar).toInt();
      int gDelta = ((randomDouble() * 2.0 - 1.0) * greenVar).toInt();
      int bDelta = ((randomDouble() * 2.0 - 1.0) * blueVar).toInt();

      int aNew = (color.alpha + aDelta).clamp(0, 255);
      int rNew = (color.red + rDelta).clamp(0, 255);
      int gNew = (color.green + gDelta).clamp(0, 255);
      int bNew = (color.blue + bDelta).clamp(0, 255);

      copy.colors[i] = new Color.fromARGB(aNew, rNew, gNew, bNew);
      i++;
    }

    return copy;
  }
}

int serializeColor(Color color) {
  return color.value;
}

Color deserializeColor(int data) {
  return new Color(data);
}

Map serializeColorSequence(ColorSequence colorSequence) {
  List<int> colors = <int>[];
  List<double> stops = <double>[];

  for (int i = 0; i < colorSequence.colors.length; i++) {
    colors.add(serializeColor(colorSequence.colors[i]));
    stops.add(colorSequence.colorStops[i]);
  }

  return {
    'colors': colors,
    'colorStops': stops,
  };
}

ColorSequence deserializeColorSequence(Map data) {
  List<int> colorsData = data['colors'].cast<int>();
  List<double> stops = data['colorStops'].cast<double>();
  List<Color> colors = <Color>[];

  for (int i = 0; i < colorsData.length; i++) {
    colors.add(deserializeColor(colorsData[i]));
  }

  return new ColorSequence(colors, stops);
}

List<double> serializeOffset(Offset offset) {
  return <double>[offset.dx, offset.dy];
}

Offset deserializeOffset(List<double> data) {
  return new Offset(data[0], data[1]);
}

int serializeBlendMode(BlendMode blendMode) {
  return blendMode.index;
}

BlendMode deserializeBlendMode(int data) {
  return BlendMode.values[data];
}

Map serializeParticleSystem(ParticleSystem system) {
  return {
    'life': system.life,
    'lifeVar': system.lifeVar,
    'posVar': serializeOffset(system.posVar),
    'startSize': system.startSize,
    'startSizeVar': system.startSizeVar,
    'endSize': system.endSize,
    'endSizeVar': system.endSizeVar,
    'startRotation': system.startRotation,
    'startRotationVar': system.startRotationVar,
    'endRotation': system.endRotation,
    'endRotationVar': system.endRotationVar,
    'rotateToMovement': system.rotateToMovement,
    'direction': system.direction,
    'directionVar': system.directionVar,
    'speed': system.speed,
    'speedVar': system.speedVar,
    'radialAcceleration': system.radialAcceleration,
    'radialAccelerationVar': system.radialAccelerationVar,
    'tangentialAcceleration': system.tangentialAcceleration,
    'tangentialAccelerationVar': system.tangentialAccelerationVar,
    'maxParticles': system.maxParticles,
    'emissionRate': system.emissionRate,
    'colorSequence': serializeColorSequence(system.colorSequence),
    'alphaVar': system.alphaVar,
    'redVar': system.redVar,
    'greenVar': system.greenVar,
    'blueVar': system.blueVar,
    'numParticlesToEmit': system.numParticlesToEmit,
    'autoRemoveOnFinish': system.autoRemoveOnFinish,
    'gravity': serializeOffset(system.gravity),
    'blendMode': serializeBlendMode(system.transferMode),
  };
}

ParticleSystem deserializeParticleSystem(Map data,
    {ParticleSystem particleSystem, SpriteTexture texture}) {
  if (particleSystem == null) particleSystem = new ParticleSystem(texture);

  particleSystem.life = data['life'];
  particleSystem.lifeVar = data['lifeVar'];
  particleSystem.posVar = deserializeOffset(data['posVar'].cast<double>());
  particleSystem.startSize = data['startSize'];
  particleSystem.startSizeVar = data['startSizeVar'];
  particleSystem.endSize = data['endSize'];
  particleSystem.endSizeVar = data['endSizeVar'];
  particleSystem.startRotation = data['startRotation'];
  particleSystem.startRotationVar = data['startRotationVar'];
  particleSystem.endRotation = data['endRotation'];
  particleSystem.endRotationVar = data['endRotationVar'];
  particleSystem.rotateToMovement = data['rotateToMovement'];
  particleSystem.direction = data['direction'];
  particleSystem.directionVar = data['directionVar'];
  particleSystem.speed = data['speed'];
  particleSystem.speedVar = data['speedVar'];
  particleSystem.radialAcceleration = data['radialAcceleration'];
  particleSystem.radialAccelerationVar = data['radialAccelerationVar'];
  particleSystem.tangentialAcceleration = data['tangentialAcceleration'];
  particleSystem.tangentialAccelerationVar = data['tangentialAccelerationVar'];
  particleSystem.maxParticles = data['maxParticles'];
  particleSystem.emissionRate = data['emissionRate'];
  particleSystem.colorSequence =
      deserializeColorSequence(data['colorSequence']);
  particleSystem.alphaVar = data['alphaVar'];
  particleSystem.redVar = data['redVar'];
  particleSystem.greenVar = data['greenVar'];
  particleSystem.blueVar = data['blueVar'];
  particleSystem.numParticlesToEmit = data['numParticlesToEmit'];
  particleSystem.autoRemoveOnFinish = data['autoRemoveOnFinish'];
  particleSystem.gravity = deserializeOffset(data['gravity'].cast<double>());
  if (data['blendMode'] != null)
    particleSystem.transferMode = deserializeBlendMode(data['blendMode']);
  else
    particleSystem.transferMode = BlendMode.plus;

  return particleSystem;
}
