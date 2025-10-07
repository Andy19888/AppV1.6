enum TaskStatus { pending, inProgress, completed, approved, rejected }

class TaskModel {
  final String id;
  final String sucursalId;
  final String title;
  final String description;
  final TaskStatus status;
  final String? repositorId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? cantidadRepuesta;
  final String? observaciones;
  final String? fotoAntes;
  final String? fotoDespues;
  final double? latitude;
  final double? longitude;
  final String? supervisorComment;

  const TaskModel({
    required this.id,
    required this.sucursalId,
    required this.title,
    required this.description,
    required this.status,
    this.repositorId,
    required this.createdAt,
    this.completedAt,
    this.cantidadRepuesta,
    this.observaciones,
    this.fotoAntes,
    this.fotoDespues,
    this.latitude,
    this.longitude,
    this.supervisorComment,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      sucursalId: json['sucursalId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      repositorId: json['repositorId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      cantidadRepuesta: json['cantidadRepuesta'] as int?,
      observaciones: json['observaciones'] as String?,
      fotoAntes: json['fotoAntes'] as String?,
      fotoDespues: json['fotoDespues'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      supervisorComment: json['supervisorComment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sucursalId': sucursalId,
      'title': title,
      'description': description,
      'status': status.name,
      'repositorId': repositorId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cantidadRepuesta': cantidadRepuesta,
      'observaciones': observaciones,
      'fotoAntes': fotoAntes,
      'fotoDespues': fotoDespues,
      'latitude': latitude,
      'longitude': longitude,
      'supervisorComment': supervisorComment,
    };
  }

  // AÑADIR ESTE MÉTODO PARA RESOLVER EL ERROR
  TaskModel copyWith({
    String? id,
    String? sucursalId,
    String? title,
    String? description,
    TaskStatus? status,
    String? repositorId,
    DateTime? createdAt,
    DateTime? completedAt,
    int? cantidadRepuesta,
    String? observaciones,
    String? fotoAntes,
    String? fotoDespues,
    double? latitude,
    double? longitude,
    String? supervisorComment,
  }) {
    return TaskModel(
      id: id ?? this.id,
      sucursalId: sucursalId ?? this.sucursalId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      repositorId: repositorId ?? this.repositorId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      cantidadRepuesta: cantidadRepuesta ?? this.cantidadRepuesta,
      observaciones: observaciones ?? this.observaciones,
      fotoAntes: fotoAntes ?? this.fotoAntes,
      fotoDespues: fotoDespues ?? this.fotoDespues,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      supervisorComment: supervisorComment ?? this.supervisorComment,
    );
  }
}