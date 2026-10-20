# Geometría del lente del hero (viewBox 600 × 600, centro 300,300). El mismo cálculo de las
# láminas del diafragma está en hero_controller.js, que lo anima; acá se dibuja el estado
# final (abierto) para que el lente se vea bien sin JavaScript o con «reducir movimiento».
module IrisHelper
  IRIS = {
    blades: 9, clip: 196, open: 160, closed: 12,
    f_stops: %w[1.4 2 2.8 4 5.6 8 11 16 22], f_step: 15,                        # grados entre números f
    distances: [["∞", -66], ["10", -50], ["5", -34], ["3", -17], ["2", 0], ["1.5", 15], ["1", 31], ["0.7", 48], ["0.5", 64]]
  }.freeze

  def iris_point(radius, deg)
    rad = (deg - 90) * Math::PI / 180
    [300 + radius * Math.cos(rad), 300 + radius * Math.sin(rad)].map { |v| v.round(1) }
  end

  # Láminas: cada una cubre lo que está más allá de un lado del polígono de apertura,
  # con un borde curvo que forma el «molinete». aperture 0 = cerrado, 1 = abierto.
  def iris_blades(aperture)
    n = IRIS[:blades]
    r = IRIS[:closed] + (IRIS[:open] - IRIS[:closed]) * aperture
    twist = -0.25 + (1 - aperture) * 0.55
    half = r * Math.tan(Math::PI / n)
    len = 520
    (0...n).map do |k|
      a = twist + k * 2 * Math::PI / n
      nx, ny = Math.cos(a), Math.sin(a)
      dx, dy = -ny, nx
      sx, sy = 300 + nx * r - dx * half, 300 + ny * r - dy * half
      p2 = [sx + dx * len, sy + dy * len]
      p3 = [p2[0] + nx * len, p2[1] + ny * len]
      e = [sx + nx * len + dx * len * 0.3, sy + ny * len + dy * len * 0.3]
      c = [sx + nx * len * 0.4 + dx * len * 0.14, sy + ny * len * 0.4 + dy * len * 0.14]
      f = ->(x, y) { "#{x.round(1)} #{y.round(1)}" }
      { fill: "M#{f.(sx, sy)}L#{f.(*p2)}L#{f.(*p3)}L#{f.(*e)}Q#{f.(*c)} #{f.(sx, sy)}Z",
        edge: "M#{f.(sx, sy)}Q#{f.(*c)} #{f.(*e)}",
        vertex: [sx, sy] }
    end
  end

  def iris_aperture_points(aperture) = iris_blades(aperture).map { |b| b[:vertex].map { |v| v.round(1) }.join(",") }.join(" ")

  # Arco rojo de profundidad de campo: más ancho cuanto más cerrado el diafragma.
  def iris_dof_arc(aperture, radius = 246)
    half = 6 + (1 - aperture) * 26
    x1, y1 = iris_point(radius, -half)
    x2, y2 = iris_point(radius, half)
    "M#{x1} #{y1} A#{radius} #{radius} 0 0 1 #{x2} #{y2}"
  end
end
