import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final Color color;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.color,
  });
}

const mockCategories = [
  CategoryModel(
    id: 'companionship',
    name: 'Companhia',
    emoji: '💬',
    description: 'Conversa, escuta e presença virtual',
    color: Color(0xFF7C4DFF),
  ),
  CategoryModel(
    id: 'tech',
    name: 'Tecnologia',
    emoji: '📱',
    description: 'Celular, computador, aplicativos',
    color: Color(0xFF00897B),
  ),
  CategoryModel(
    id: 'health',
    name: 'Saúde',
    emoji: '💊',
    description: 'Medicamentos, consultas e bem-estar',
    color: Color(0xFFE53935),
  ),
  CategoryModel(
    id: 'recreation',
    name: 'Recreação',
    emoji: '🎮',
    description: 'Jogos, música e atividades lúdicas',
    color: Color(0xFFFF6F00),
  ),
  CategoryModel(
    id: 'admin',
    name: 'Administrativo',
    emoji: '📄',
    description: 'Contas, documentos e burocracias',
    color: Color(0xFF1565C0),
  ),
  CategoryModel(
    id: 'education',
    name: 'Educação',
    emoji: '📚',
    description: 'Leitura, cursos e aprendizado',
    color: Color(0xFF2E7D32),
  ),
];
