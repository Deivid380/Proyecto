import React, { useMemo } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { Sale } from '../types';
import { TrendingUp, DollarSign, Wallet, ArrowUpRight, ArrowDownRight } from 'lucide-react';

interface DashboardProps {
  sales: Sale[];
}

const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

const Dashboard: React.FC<DashboardProps> = ({ sales }) => {
  const stats = useMemo(() => {
    const totalRevenue = sales.reduce((acc, sale) => acc + sale.total, 0);
    const totalTransactions = sales.length;
    const averageSale = totalTransactions > 0 ? totalRevenue / totalTransactions : 0;
    
    const topProducts = sales
      .flatMap(sale => sale.items)
      .reduce((acc, item) => {
        acc[item.name] = (acc[item.name] || 0) + item.quantity;
        return acc;
      }, {} as { [key: string]: number });

    const sortedTopProducts = Object.entries(topProducts)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .map(([name, sales]) => ({ name, sales }));

    return { totalRevenue, totalTransactions, averageSale, topProducts: sortedTopProducts };
  }, [sales]);

  return (
    <div className="p-6 space-y-6 animate-in fade-in duration-300 bg-white min-h-full">
      <header className="flex justify-between items-center pb-4 border-b border-slate-100">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Tablero de Control</h1>
          <p className="text-slate-500 text-sm mt-1">Resumen general del negocio</p>
        </div>
        <div className="text-right hidden md:block">
          <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Fecha</p>
          <p className="text-base font-medium text-slate-600">{new Date().toLocaleDateString('es-MX', { weekday: 'long', day: 'numeric', month: 'long' })}</p>
        </div>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <StatCard icon={DollarSign} title="Ingresos Totales" value={`$${stats.totalRevenue.toFixed(2)}`} change="+5.2%" changeType="increase" />
        <StatCard icon={Wallet} title="Transacciones" value={stats.totalTransactions.toString()} change="+12" changeType="increase" />
        <StatCard icon={TrendingUp} title="Venta Promedio" value={`$${stats.averageSale.toFixed(2)}`} change="-1.8%" changeType="decrease" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        <div className="lg:col-span-3 bg-white p-6 rounded-xl shadow-sm border border-slate-200">
          <h3 className="text-base font-semibold text-slate-800 mb-4">Ventas Recientes</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={sales.slice(-10)} margin={{ top: 5, right: 20, left: -10, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="date" tick={{ fill: '#64748b', fontSize: 12 }} tickFormatter={(tick) => new Date(tick).toLocaleDateString('es-MX', { day: '2-digit', month: 'short' })} />
                <YAxis tick={{ fill: '#64748b', fontSize: 12 }} tickFormatter={(tick) => `$${tick}`} />
                <Tooltip
                  cursor={{ fill: 'rgba(59, 130, 246, 0.05)' }}
                  contentStyle={{ backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '0.75rem', padding: '8px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)' }}
                  labelStyle={{ fontWeight: 'bold' }}
                  itemStyle={{ fontSize: '12px' }}
                  labelFormatter={(label) => new Date(label).toLocaleDateString('es-MX', { month: 'long', day: 'numeric' })}
                />
                <Bar dataKey="total" fill="#3b82f6" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
        <div className="lg:col-span-2 bg-white p-6 rounded-xl shadow-sm border border-slate-200">
          <h3 className="text-base font-semibold text-slate-800 mb-4">Top 5 Productos</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={stats.topProducts} dataKey="sales" nameKey="name" cx="50%" cy="50%" innerRadius={60} outerRadius={80} fill="#8884d8" paddingAngle={5} label>
                   {stats.topProducts.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip 
                  contentStyle={{ backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '0.75rem', padding: '8px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)' }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
};

const StatCard = ({ icon: Icon, title, value, change, changeType }: { icon: React.ElementType, title: string, value: string, change: string, changeType: 'increase' | 'decrease' }) => (
    <div className="bg-white p-5 rounded-xl shadow-sm border border-slate-200 flex items-start justify-between">
    <div>
      <p className="text-sm font-medium text-slate-500">{title}</p>
      <p className="text-2xl font-bold text-slate-900 mt-2">{value}</p>
      <div className={`flex items-center gap-1 mt-2 text-xs font-medium ${changeType === 'increase' ? 'text-emerald-600' : 'text-rose-600'}`}>
        {changeType === 'increase' ? <ArrowUpRight size={14} /> : <ArrowDownRight size={14} />}
        <span>{change} vs ayer</span>
      </div>
    </div>
    <div className={`p-2.5 rounded-lg ${changeType === 'increase' ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'}`}>
      <Icon size={20} />
    </div>
  </div>
);

export default Dashboard;
