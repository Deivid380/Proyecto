import { Product, Sale } from '../types';

const PRODUCTS_KEY = 'quicksale_products';
const SALES_KEY = 'quicksale_sales';

const DEFAULT_PRODUCTS: Product[] = [
  { id: '1', name: 'Coca Cola 600ml', price: 25, stock: 50, category: 'Bebidas', barcode: '7501055310808', imageUrl: 'https://picsum.photos/200/200?random=1' },
  { id: '2', name: 'Sabritas Original 45g', price: 18, stock: 30, category: 'Snacks', barcode: '7501011123456', imageUrl: 'https://picsum.photos/200/200?random=2' },
  { id: '3', name: 'Leche Alpura 1L', price: 28, stock: 20, category: 'Lácteos', barcode: '7501055900034', imageUrl: 'https://picsum.photos/200/200?random=3' },
  { id: '4', name: 'Pan Bimbo Blanco', price: 45, stock: 15, category: 'Panadería', barcode: '7501000111222', imageUrl: 'https://picsum.photos/200/200?random=4' },
  { id: '5', name: 'Jabón Zote Rosa', price: 12, stock: 100, category: 'Limpieza', barcode: '7501020304050', imageUrl: 'https://picsum.photos/200/200?random=5' },
];

export const getProducts = (): Product[] => {
  const stored = localStorage.getItem(PRODUCTS_KEY);
  if (!stored) {
    localStorage.setItem(PRODUCTS_KEY, JSON.stringify(DEFAULT_PRODUCTS));
    return DEFAULT_PRODUCTS;
  }
  return JSON.parse(stored);
};

export const saveProduct = (product: Product): void => {
  const products = getProducts();
  const index = products.findIndex(p => p.id === product.id);
  if (index >= 0) {
    products[index] = product;
  } else {
    products.push(product);
  }
  localStorage.setItem(PRODUCTS_KEY, JSON.stringify(products));
};

export const deleteProduct = (id: string): void => {
  const products = getProducts().filter(p => p.id !== id);
  localStorage.setItem(PRODUCTS_KEY, JSON.stringify(products));
};

export const getSales = (): Sale[] => {
  const stored = localStorage.getItem(SALES_KEY);
  return stored ? JSON.parse(stored) : [];
};

export const saveSale = (sale: Sale): void => {
  const sales = getSales();
  sales.push(sale);
  localStorage.setItem(SALES_KEY, JSON.stringify(sales));

  // Update stock
  const products = getProducts();
  sale.items.forEach(item => {
    const productIndex = products.findIndex(p => p.id === item.id);
    if (productIndex >= 0) {
      products[productIndex].stock = Math.max(0, products[productIndex].stock - item.quantity);
    }
  });
  localStorage.setItem(PRODUCTS_KEY, JSON.stringify(products));
};
