// Rutas nombradas. El comentario indica qué recibe en `arguments`.
class Rutas {
  static const String inicio = '/';
  static const String detalle = '/detalle'; // Equipo (para pintar el Hero desde el primer cuadro)
  static const String formEquipo = '/equipo/form'; // Equipo? (null = crear); pop(true) si guardó
  static const String formRevision = '/revision/form'; // Equipo; pop(true) si guardó
  static const String pendientes = '/pendientes';
  static const String vidaUtil = '/vida-util';
}
