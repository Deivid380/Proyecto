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
    <div className="p-6 h-full flex flex-col animate-in fade-in duration-300 overflow-hidden bg-white">
      <header className="flex flex-col md:flex-row md:justify-between md:items-center gap-4 mb-6 pb-4 border-b border-slate-100">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Inventario</h1>
          <p className="text-slate-500 text-sm mt-1">Gestión de stock y precios</p>
        </div>
        <button
          onClick={handleAddNew}
          className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center justify-center gap-2 transition-colors font-semibold text-sm active:scale-95"
        >
          <Plus size={18} />
          Nuevo Producto
        </button>
      </header>

      <div className="mb-6 relative">
        <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Buscar por nombre o código de barras..."
          className="w-full bg-white border border-slate-200 rounded-lg pl-10 pr-4 py-2.5 text-sm"
        />
      </div>

      <div className="flex-1 overflow-y-auto -mx-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 px-6 pb-6">
          {filteredProducts.map(product => (
            <div key={product.id} className="bg-white rounded-xl shadow-sm border border-slate-100 overflow-hidden flex flex-col group">
              <div className="h-36 bg-slate-50 flex items-center justify-center relative">
                {product.imageUrl ? (
                  <img src={product.imageUrl} alt={product.name} className="w-full h-full object-cover" />
                ) : (
                  <Package size={40} className="text-slate-300" />
                )}
                 <div className="absolute top-2 right-2 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button onClick={() => handleEdit(product)} className="p-2 bg-white/70 backdrop-blur-sm rounded-lg text-slate-700 hover:bg-white">
                      <Edit2 size={16} />
                    </button>
                    <button onClick={() => handleDelete(product.id)} className="p-2 bg-white/70 backdrop-blur-sm rounded-lg text-rose-500 hover:bg-white">
                      <Trash2 size={16} />
                    </button>
                  </div>
              </div>
              <div className="p-4 flex-1 flex flex-col">
                <h3 className="font-semibold text-base text-slate-800">{product.name}</h3>
                <p className="text-xs text-slate-500">{product.category}</p>
                <div className="mt-3 flex-1 flex items-end justify-between">
                  <div>
                    <p className="text-xl font-bold text-slate-900">${product.price.toFixed(2)}</p>
                    <p className="text-xs font-medium text-slate-500">Stock: {product.stock}</p>
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
  onSave: (product: Product) => void;
  onClose: () => void;
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
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-end md:items-center justify-center z-[60] p-0 md:p-4 animate-in fade-in duration-200">
      <div className="bg-white rounded-t-2xl md:rounded-xl shadow-lg w-full max-w-md max-h-[90vh] flex flex-col animate-in slide-in-from-bottom-10 duration-300">
        <div className="p-4 border-b border-slate-100 flex justify-between items-center">
          <h2 className="text-lg font-bold text-slate-800">
            {product ? 'Editar Producto' : 'Nuevo Producto'}
          </h2>
          <button onClick={onClose} className="bg-slate-100 p-1.5 rounded-lg text-slate-500 hover:text-slate-800">
            <X size={18} />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="md:col-span-2">
              <label className="text-sm font-medium text-slate-600">Nombre del Producto</label>
              <input type="text" name="name" value={formData.name} onChange={handleChange} className="w-full mt-1 p-2.5 border border-slate-200 rounded-lg text-sm" required />
            </div>
            <div>
              <label className="text-sm font-medium text-slate-600">Precio</label>
              <input type="number" step="0.01" name="price" value={formData.price} onChange={handleChange} className="w-full mt-1 p-2.5 border border-slate-200 rounded-lg text-sm" required />
            </div>
            <div>
              <label className="text-sm font-medium text-slate-600">Stock</label>
              <input type="number" name="stock" value={formData.stock} onChange={handleChange} className="w-full mt-1 p-2.5 border border-slate-200 rounded-lg text-sm" required />
            </div>
            <div className="md:col-span-2">
              <label className="text-sm font-medium text-slate-600">Categoría</label>
              <input type="text" name="category" value={formData.category} onChange={handleChange} className="w-full mt-1 p-2.5 border border-slate-200 rounded-lg text-sm" />
            </div>
            <div className="md:col-span-2">
              <label className="text-sm font-medium text-slate-600">Código de Barras</label>
              <input type="text" name="barcode" value={formData.barcode} onChange={handleChange} className="w-full mt-1 p-2.5 border border-slate-200 rounded-lg text-sm" />
            </div>
          </div>
          {formData.imageUrl && (
            <div className="flex flex-col items-center">
              <img src={formData.imageUrl} alt="Generated" className="w-24 h-24 rounded-lg object-cover" />
              <button type="button" onClick={() => setFormData(prev => ({ ...prev, imageUrl: '' }))} className="mt-2 text-xs text-red-500 hover:underline">
                Quitar imagen
              </button>
            </div>
          )}
        </form>
        <div className="p-4 bg-slate-50/50 border-t border-slate-100">
          <button type="submit" className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg text-sm font-semibold flex items-center justify-center gap-2">
            <Save size={16} />
            Guardar Producto
          </button>
        </div>
      </div>
    </div>
  );
};

export default Inventory;
