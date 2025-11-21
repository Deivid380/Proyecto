import React, { useState } from 'react';
import { Product } from '../types';
import { saveProduct, deleteProduct } from '../services/storageService';
import { Plus, Search, Edit2, Trash2, X, Save, Package } from 'lucide-react';

interface InventoryProps {
  products: Product[];
  refreshProducts: () => void;
}

const Inventory: React.FC<InventoryProps> = ({ products, refreshProducts }) => {
  const [search, setSearch] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);

  const filteredProducts = products.filter(p =>
    p.name.toLowerCase().includes(search.toLowerCase()) ||
    p.barcode.includes(search)
  );

  const handleEdit = (product: Product) => {
    setEditingProduct(product);
    setIsModalOpen(true);
  };

  const handleAddNew = () => {
    setEditingProduct(null);
    setIsModalOpen(true);
  };

  const handleDelete = (id: string) => {
    if (confirm('¿Estás seguro de eliminar este producto?')) {
      deleteProduct(id);
      refreshProducts();
    }
  };

  const handleSave = (product: Product) => {
    saveProduct(product);
    refreshProducts();
    setIsModalOpen(false);
  };

  return (
    <div className="p-6 h-full flex flex-col animate-in fade-in duration-300 overflow-hidden bg-slate-50">
      <header className="flex flex-col md:flex-row md:justify-between md:items-center gap-4 mb-8">
        <div>
          <h1 className="text-3xl font-black text-slate-800 tracking-tight">Inventario</h1>
          <p className="text-slate-500 font-medium mt-1">Gestión de stock y precios</p>
        </div>
        <button
          onClick={handleAddNew}
          className="bg-slate-900 hover:bg-slate-800 text-white px-6 py-4 rounded-2xl flex items-center justify-center gap-2 transition-colors shadow-lg font-bold text-lg active:scale-95"
        >
          <Plus size={24} />
          Nuevo Producto
        </button>
      </header>

      <div className="mb-6 relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Buscar por nombre o código de barras..."
          className="w-full bg-white border border-slate-200 rounded-xl pl-12 pr-4 py-4 text-lg"
        />
      </div>

      <div className="flex-1 overflow-y-auto -mx-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 px-6">
          {filteredProducts.map(product => (
            <div key={product.id} className="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden flex flex-col">
              <div className="h-40 bg-slate-100 flex items-center justify-center">
                {product.imageUrl ? (
                  <img src={product.imageUrl} alt={product.name} className="w-full h-full object-cover" />
                ) : (
                  <Package size={48} className="text-slate-400" />
                )}
              </div>
              <div className="p-4 flex-1 flex flex-col">
                <h3 className="font-bold text-lg text-slate-800">{product.name}</h3>
                <p className="text-sm text-slate-500">{product.category}</p>
                <div className="mt-4 flex-1 flex items-end justify-between">
                  <div>
                    <p className="text-2xl font-black text-slate-900">${product.price.toFixed(2)}</p>
                    <p className="text-sm font-medium text-slate-500">Stock: {product.stock}</p>
                  </div>
                  <div className="flex gap-2">
                    <button onClick={() => handleEdit(product)} className="p-3 bg-slate-100 rounded-full text-slate-600 hover:bg-slate-200">
                      <Edit2 size={18} />
                    </button>
                    <button onClick={() => handleDelete(product.id)} className="p-3 bg-rose-100 rounded-full text-rose-600 hover:bg-rose-200">
                      <Trash2 size={18} />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {isModalOpen && (
        <ProductModal
          product={editingProduct}
          onClose={() => setIsModalOpen(false)}
          onSave={handleSave}
        />
      )}
    </div>
  );
};

interface ProductModalProps {
  product: Product | null;
  onClose: () => void;
  onSave: (product: Product) => void;
}

const ProductModal: React.FC<ProductModalProps> = ({ product, onClose, onSave }) => {
  const [formData, setFormData] = useState<Product>(
    product || { id: Date.now().toString(), name: '', price: 0, stock: 0, category: '', barcode: '', imageUrl: '' }
  );

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: name === 'price' || name === 'stock' ? parseFloat(value) || 0 : value }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
  };

  return (
    <div className="fixed inset-0 bg-slate-900/70 backdrop-blur-sm flex items-end md:items-center justify-center z-[60] p-0 md:p-4 animate-in fade-in duration-200">
      <div className="bg-white rounded-t-3xl md:rounded-3xl shadow-2xl w-full max-w-lg max-h-[90vh] flex flex-col animate-in slide-in-from-bottom-10 duration-300">
        <div className="p-6 border-b border-slate-100 flex justify-between items-center">
          <h2 className="text-2xl font-black text-slate-800">
            {product ? 'Editar Producto' : 'Nuevo Producto'}
          </h2>
          <button onClick={onClose} className="bg-slate-100 p-2 rounded-full text-slate-500 hover:text-slate-800">
            <X size={24} />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="md:col-span-2">
              <label className="font-medium text-slate-700">Nombre del Producto</label>
              <input type="text" name="name" value={formData.name} onChange={handleChange} className="w-full mt-2 p-3 border border-slate-300 rounded-xl" required />
            </div>
            <div>
              <label className="font-medium text-slate-700">Precio</label>
              <input type="number" name="price" value={formData.price} onChange={handleChange} className="w-full mt-2 p-3 border border-slate-300 rounded-xl" required />
            </div>
            <div>
              <label className="font-medium text-slate-700">Stock</label>
              <input type="number" name="stock" value={formData.stock} onChange={handleChange} className="w-full mt-2 p-3 border border-slate-300 rounded-xl" required />
            </div>
            <div className="md:col-span-2">
              <label className="font-medium text-slate-700">Categoría</label>
              <input type="text" name="category" value={formData.category} onChange={handleChange} className="w-full mt-2 p-3 border border-slate-300 rounded-xl" />
            </div>
            <div className="md:col-span-2">
              <label className="font-medium text-slate-700">Código de Barras</label>
              <input type="text" name="barcode" value={formData.barcode} onChange={handleChange} className="w-full mt-2 p-3 border border-slate-300 rounded-xl" />
            </div>
          </div>
          {formData.imageUrl && (
            <div className="flex flex-col items-center">
              <img src={formData.imageUrl} alt="Generated" className="w-32 h-32 rounded-lg object-cover" />
              <button type="button" onClick={() => setFormData(prev => ({ ...prev, imageUrl: '' }))} className="mt-2 text-sm text-red-500">
                Quitar imagen
              </button>
            </div>
          )}
        </form>
        <div className="p-6 bg-slate-50 border-t border-slate-100">
          <button onClick={handleSubmit} className="w-full bg-slate-900 text-white py-4 rounded-2xl text-lg font-bold flex items-center justify-center gap-2">
            <Save size={20} />
            Guardar Producto
          </button>
        </div>
      </div>
    </div>
  );
};

export default Inventory;
