'use client';

import DashboardLayout from '@/components/layout/DashboardLayout';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { reviewsApi } from '@/lib/api/endpoints';
import { Star } from 'lucide-react';
import toast from 'react-hot-toast';

export default function ReviewsPage() {
  const queryClient = useQueryClient();
  const { data, isLoading } = useQuery({
    queryKey: ['admin-reviews'],
    queryFn: () => reviewsApi.list().then(r => r.data),
  });

  const approveMut = useMutation({
    mutationFn: (id: string) => reviewsApi.approve(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-reviews'] });
      toast.success('Review approved');
    },
    onError: (err: any) => toast.error(err?.response?.data?.detail || err?.response?.data?.message || 'Failed to approve review'),
  });

  return (
    <DashboardLayout>
      <h1 className="text-2xl font-bold mb-6">Reviews</h1>

      {isLoading ? (
        <p className="text-gray-500">Loading...</p>
      ) : (
        <div className="space-y-4">
          {data?.data?.length === 0 ? (
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 text-center text-gray-400 text-sm">No reviews yet</div>
          ) : data?.data?.map((r: any) => (
            <div key={r.id} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2 mb-2">
                    <div className="flex">
                      {[1, 2, 3, 4, 5].map(s => (
                        <Star key={s} size={16} className={s <= r.rating ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'} />
                      ))}
                    </div>
                    <span className="text-xs text-gray-400">by User {r.user_id?.slice(0, 8)}</span>
                  </div>
                  <p className="text-sm text-gray-700 mb-1">{r.comment || 'No comment'}</p>
                  <p className="text-xs text-gray-400">Product: {r.product_id?.slice(0, 8)} | Order: {r.order_id?.slice(0, 8)}</p>
                  <p className="text-xs text-gray-400 mt-1">{new Date(r.created_at).toLocaleString()}</p>
                </div>
                <div className="flex items-center gap-2">
                  {!r.is_approved ? (
                    <button onClick={() => approveMut.mutate(r.id)}
                      className="px-3 py-1 bg-green-100 text-green-700 rounded text-xs font-medium hover:bg-green-200">
                      Approve
                    </button>
                  ) : (
                    <span className="px-2 py-1 bg-green-100 text-green-700 rounded-full text-xs">Approved</span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </DashboardLayout>
  );
}
