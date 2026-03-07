class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String telefono;
  final String negocio;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.negocio,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'negocio': negocio,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      negocio: map['negocio'] ?? '',
    );
  }
}
