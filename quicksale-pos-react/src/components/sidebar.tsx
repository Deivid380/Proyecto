import React from 'react';
import { LayoutDashboard, ShoppingCart, Package } from 'lucide-react';

interface SidebarProps {
  currentView: string;
  onNavigate: (view: string) => void;
}

const Sidebar: React.FC<SidebarProps> = ({ currentView, onNavigate }) => {
  const menuItems = [
    { id: 'pos', label: 'Caja', icon: ShoppingCart },
    { id: 'inventory', label: 'Almacén', icon: Package },
    { id: 'dashboard', label: 'Reportes', icon: LayoutDashboard },
  ];

  return (
    <>
      {/* Desktop Sidebar */}
      <div className="hidden md:flex w-20 lg:w-60 bg-slate-900 h-screen flex-col sticky top-0 z-50">
        <div className="p-4 flex items-center justify-center lg:justify-start">
          <div className="bg-blue-600 text-white p-2 rounded-lg">
            <ShoppingCart size={24} strokeWidth={2.5} />
          </div>
          <div className="hidden lg:block ml-3">
            <span className="text-lg font-bold text-white block tracking-tight">QuickSale</span>
          </div>
        </div>
        <nav className="flex-1 p-3 space-y-2">
          {menuItems.map(item => (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={`w-full flex items-center justify-center lg:justify-start gap-3 p-3 rounded-lg font-semibold text-sm transition-colors ${
                currentView === item.id
                  ? 'bg-slate-800 text-white'
                  : 'text-slate-400 hover:bg-slate-800 hover:text-white'
              }`}
            >
              <item.icon size={22} strokeWidth={2} />
              <span className="hidden lg:block">{item.label}</span>
            </button>
          ))}
        </nav>
      </div>

      {/* Mobile Bottom Bar */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 bg-slate-900 border-t border-slate-800 flex justify-around pb-safe z-50">
        {menuItems.map(item => (
          <button
            key={item.id}
            onClick={() => onNavigate(item.id)}
            className={`flex flex-col items-center justify-center gap-1 p-2 flex-1 transition-colors ${
              currentView === item.id ? 'text-blue-500' : 'text-slate-400'
            }`}
          >
            <item.icon size={22} />
            <span className="text-xs font-semibold">{item.label}</span>
          </button>
        ))}
      </div>
    </>
  );
};

export default Sidebar;
