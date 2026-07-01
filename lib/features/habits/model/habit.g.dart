// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

// This adapter is committed so the app compiles out-of-the-box. It mirrors the
// output of `dart run build_runner build` for [Habit]; re-running build_runner
// regenerates an identical file.

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 3;

  @override
  Habit read(BinaryReader reader) {
    final int numOfFields = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      title: fields[1] as String,
      emoji: fields[2] as String? ?? '⭐',
      colorValue: fields[3] as int? ?? 0xFF6750A4,
      createdAt: fields[4] as DateTime,
      completedDates:
          (fields[5] as List?)?.cast<DateTime>() ?? <DateTime>[],
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.completedDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
