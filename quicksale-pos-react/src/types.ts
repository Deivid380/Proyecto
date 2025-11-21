export interface Product {
  id: string;
  name: string;
  price: number;
  stock: number;
  category: string;
  barcode: string;
  imageUrl?: string;
}

export interface CartItem extends Product {
  quantity: number;
}

export interface Sale {
  id: string;
  date: string;
  total: number;
  items: CartItem[];
  paymentMethod: 'cash' | 'card';
}

