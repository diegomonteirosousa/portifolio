/// Alimento do banco local. Valores aproximados por porção
/// (baseados em tabelas brasileiras de composição, como a TACO).
class Food {
  final String name;
  final String portion;
  final String category;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  const Food(this.name, this.portion, this.category, this.kcal, this.protein,
      this.carbs, this.fat);
}

const foodCategories = [
  'Café',
  'Frutas',
  'Pratos',
  'Carnes e ovos',
  'Lanches',
  'Bebidas',
];

const foodDatabase = <Food>[
  // Café da manhã
  Food('Pão francês', '1 unidade (50 g)', 'Café', 150, 4.0, 29, 1.5),
  Food('Pão de forma integral', '2 fatias (50 g)', 'Café', 125, 6.0, 22, 1.8),
  Food('Tapioca (só a goma)', '1 média (60 g)', 'Café', 210, 0.1, 52, 0),
  Food('Cuscuz de milho', '1 xícara (120 g)', 'Café', 136, 2.6, 30, 0.8),
  Food('Pão de queijo', '2 unidades (50 g)', 'Café', 180, 3.0, 18, 10),
  Food('Queijo minas frescal', '1 fatia (30 g)', 'Café', 79, 5.2, 1, 6),
  Food('Requeijão light', '1 colher de sopa (30 g)', 'Café', 54, 3.5, 1, 4),
  Food('Manteiga', '1 colher de chá (5 g)', 'Café', 36, 0, 0, 4),
  Food('Leite integral', '1 copo (200 ml)', 'Café', 124, 6.4, 9.6, 6.6),
  Food('Leite desnatado', '1 copo (200 ml)', 'Café', 70, 6.8, 10, 0.4),
  Food('Iogurte natural', '1 pote (170 g)', 'Café', 105, 7.0, 8, 5),
  Food('Aveia em flocos', '2 colheres de sopa (30 g)', 'Café', 118, 4.4, 20, 2.6),
  Food('Granola', '3 colheres de sopa (30 g)', 'Café', 130, 3.0, 20, 4.5),
  Food('Café com açúcar', '1 xícara (100 ml)', 'Café', 40, 0.2, 10, 0),
  Food('Café sem açúcar', '1 xícara (100 ml)', 'Café', 2, 0.1, 0, 0),
  // Frutas
  Food('Banana prata', '1 unidade (70 g)', 'Frutas', 69, 0.9, 18, 0.1),
  Food('Maçã', '1 unidade (130 g)', 'Frutas', 73, 0.4, 20, 0.2),
  Food('Mamão papaya', '½ unidade (150 g)', 'Frutas', 60, 0.8, 15, 0.2),
  Food('Laranja', '1 unidade (180 g)', 'Frutas', 66, 1.8, 16, 0.2),
  Food('Morango', '1 xícara (150 g)', 'Frutas', 45, 1.4, 10, 0.5),
  Food('Manga', '½ unidade (100 g)', 'Frutas', 72, 0.4, 19, 0.2),
  Food('Uva', '1 cacho pequeno (100 g)', 'Frutas', 53, 0.7, 14, 0.2),
  Food('Abacate', '2 colheres de sopa (60 g)', 'Frutas', 58, 0.7, 4, 5),
  Food('Açaí na tigela', '300 ml', 'Frutas', 330, 3.0, 55, 12),
  // Pratos e acompanhamentos
  Food('Arroz branco', '4 colheres de sopa (100 g)', 'Pratos', 128, 2.5, 28, 0.2),
  Food('Arroz integral', '4 colheres de sopa (100 g)', 'Pratos', 124, 2.6, 26, 1),
  Food('Feijão carioca', '1 concha (140 g)', 'Pratos', 106, 7.0, 19, 0.7),
  Food('Feijão preto', '1 concha (140 g)', 'Pratos', 108, 6.3, 20, 0.7),
  Food('Macarrão cozido', '1 xícara (140 g)', 'Pratos', 196, 6.5, 40, 1),
  Food('Batata cozida', '1 média (130 g)', 'Pratos', 68, 1.5, 15.5, 0),
  Food('Batata-doce cozida', '100 g', 'Pratos', 77, 0.6, 18, 0.1),
  Food('Mandioca cozida', '100 g', 'Pratos', 125, 0.6, 30, 0.3),
  Food('Farofa', '2 colheres de sopa (30 g)', 'Pratos', 122, 0.7, 22, 3.5),
  Food('Salada verde', '1 prato (100 g)', 'Pratos', 15, 1.3, 2.5, 0.2),
  Food('Legumes cozidos', '1 xícara (100 g)', 'Pratos', 40, 1.5, 8, 0.3),
  Food('Feijoada', '1 concha (200 g)', 'Pratos', 234, 17, 13, 13),
  Food('Strogonoff de frango', '1 concha (150 g)', 'Pratos', 230, 18, 6, 15),
  Food('Lasanha', '1 pedaço (200 g)', 'Pratos', 330, 17, 28, 16),
  Food('Prato feito (PF / marmitex)', '1 prato médio', 'Pratos', 700, 38, 85, 20),
  // Carnes e ovos
  Food('Peito de frango grelhado', '100 g', 'Carnes e ovos', 159, 32, 0, 2.5),
  Food('Coxa de frango assada', '1 unidade (100 g)', 'Carnes e ovos', 215, 27, 0, 11),
  Food('Patinho moído', '100 g', 'Carnes e ovos', 219, 35.9, 0, 7.3),
  Food('Alcatra grelhada', '100 g', 'Carnes e ovos', 241, 31.9, 0, 11.6),
  Food('Picanha', '100 g', 'Carnes e ovos', 289, 26, 0, 20),
  Food('Tilápia grelhada', '100 g', 'Carnes e ovos', 128, 26, 0, 2.7),
  Food('Salmão grelhado', '100 g', 'Carnes e ovos', 230, 24, 0, 14),
  Food('Atum em água', '100 g', 'Carnes e ovos', 116, 26, 0, 1),
  Food('Ovo cozido', '1 unidade (50 g)', 'Carnes e ovos', 72, 6.3, 0.4, 4.8),
  Food('Ovo frito', '1 unidade', 'Carnes e ovos', 108, 7.0, 0.4, 8.8),
  Food('Omelete (2 ovos)', '1 porção', 'Carnes e ovos', 180, 12, 1, 14),
  // Lanches
  Food('Whey protein', '1 scoop (30 g)', 'Lanches', 120, 24, 3, 1.5),
  Food('Pasta de amendoim', '1 colher de sopa (15 g)', 'Lanches', 90, 4.0, 3, 7.5),
  Food('Castanha-do-pará', '3 unidades (12 g)', 'Lanches', 79, 1.7, 1.5, 7.9),
  Food('Amendoim torrado', '30 g', 'Lanches', 182, 8.2, 5.6, 14.6),
  Food('Barra de proteína', '1 unidade (60 g)', 'Lanches', 210, 15, 22, 7),
  Food('Biscoito integral', '6 unidades (30 g)', 'Lanches', 135, 2.5, 21, 4.5),
  Food('Chocolate ao leite', '1 quadrado (25 g)', 'Lanches', 135, 1.8, 15, 7.5),
  Food('Brigadeiro', '1 unidade (20 g)', 'Lanches', 80, 1.0, 12, 3),
  Food('Pizza de muçarela', '1 fatia (100 g)', 'Lanches', 272, 11, 30, 12),
  Food('Hambúrguer de lanchonete', '1 unidade', 'Lanches', 500, 25, 40, 26),
  Food('Coxinha', '1 unidade (100 g)', 'Lanches', 280, 9, 30, 14),
  Food('Pastel de carne', '1 unidade', 'Lanches', 280, 9, 25, 16),
  Food('Esfiha de carne', '1 unidade (60 g)', 'Lanches', 160, 7, 22, 5),
  // Bebidas
  Food('Refrigerante', '1 lata (350 ml)', 'Bebidas', 149, 0, 37, 0),
  Food('Refrigerante zero', '1 lata (350 ml)', 'Bebidas', 1, 0, 0, 0),
  Food('Suco de laranja natural', '1 copo (300 ml)', 'Bebidas', 135, 2.0, 31, 0.3),
  Food('Vitamina de banana com leite', '1 copo (300 ml)', 'Bebidas', 220, 9, 36, 5),
  Food('Água de coco', '1 copo (300 ml)', 'Bebidas', 66, 0, 15, 0),
  Food('Cerveja', '1 lata (350 ml)', 'Bebidas', 147, 1.6, 12, 0),
];
