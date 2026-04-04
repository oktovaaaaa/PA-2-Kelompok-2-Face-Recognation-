// src/app/(dashboard)/jabatan/page.tsx
import PositionList from '@views/jabatan/PositionList'

export const metadata = {
  title: 'Manajemen Jabatan | Admin Dashboard',
  description: 'Kelola struktur jabatan dan gaji pokok karyawan perusahaan.'
}

export default function JabatanPage() {
  return <PositionList />
}
