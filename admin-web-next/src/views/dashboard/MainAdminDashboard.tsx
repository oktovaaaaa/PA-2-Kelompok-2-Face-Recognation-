// src/views/dashboard/MainAdminDashboard.tsx
'use client'

import { useState, useEffect } from 'react'
import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Button from '@mui/material/Button'
import Box from '@mui/material/Box'
import CircularProgress from '@mui/material/CircularProgress'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { dashboardService, DashboardSummary, AttendanceTrend } from '@/libs/dashboardService'
import InviteQRModal from './InviteQRModal'
import { formatImageUrl, settingService, Profile } from '@/libs/settingService'

// Component Imports
import AttendanceSummaryPie from './AttendanceSummaryPie'
import AttendanceTrendLine from './AttendanceTrendLine'
import RecentAttendanceTable from './RecentAttendanceTable'

const MainAdminDashboard = () => {
    const [summary, setSummary] = useState<DashboardSummary | null>(null)
    const [trend, setTrend] = useState<AttendanceTrend | null>(null)
    const [profile, setProfile] = useState<Profile | null>(null)
    const [loading, setLoading] = useState(true)
    const [qrModalOpen, setQrModalOpen] = useState(false)
    const router = useRouter()

    const fetchData = async () => {
        setLoading(true)
        try {
            const [sumData, trendData, profData] = await Promise.all([
                dashboardService.getSummary(),
                dashboardService.getTrend('7days'),
                settingService.getProfile()
            ])
            setSummary(sumData)
            setTrend(trendData)
            setProfile(profData)
        } catch (error) {
            console.error('Error fetching dashboard data:', error)
        } finally {
            setLoading(false)
        }
    }

    useEffect(() => {
        fetchData()
    }, [])

    const quickActions = [
        { icon: 'ri-calendar-check-line', label: 'Perizinan', color: 'bg-amber-100 text-amber-600', url: '/cuti' },
        { icon: 'ri-team-line', label: 'Karyawan', color: 'bg-blue-100 text-blue-600', url: '/karyawan' },
        { icon: 'ri-briefcase-line', label: 'Jabatan', color: 'bg-indigo-100 text-indigo-600', url: '/jabatan' },
        { icon: 'ri-settings-4-line', label: 'Pengaturan', color: 'bg-slate-100 text-slate-600', url: '/operasional' }
    ]

    if (loading) return (
        <Box className='flex flex-col items-center justify-center p-14 gap-6 bg-white rounded-3xl shadow-sm'>
            <CircularProgress color='primary' size={40} />
            <Typography variant='caption' className='font-bold uppercase tracking-widest text-slate-400'>
                Sinkronisasi Data Dashboard...
            </Typography>
        </Box>
    )

    return (
        <Grid container spacing={6}>
            {/* Header Sapaan */}
            <Grid item xs={12}>
                <Card className='bg-gradient-to-r from-slate-900 to-blue-900 text-white shadow-xl rounded-3xl overflow-hidden border-none'>
                    <CardContent className='p-8 flex flex-col sm:flex-row justify-between items-center gap-6'>
                        <Box className='flex items-center gap-6'>
                            <Box className='p-1 border-2 border-white/20 rounded-full'>
                                <img 
                                    src={formatImageUrl(profile?.photo_url) || '/images/avatars/1.png'} 
                                    alt='Avatar' 
                                    className='w-16 h-16 rounded-full object-cover shadow-lg'
                                />
                            </Box>
                            <Box>
                                <Typography variant='h5' className='font-bold text-white'>
                                    Halo, {profile?.name?.split(' ')[0] || 'Admin'} 👋
                                </Typography>
                                <Typography className='text-white/60 text-sm'>
                                    Semua data operasional terintegrasi dalam kendali Anda.
                                </Typography>
                            </Box>
                        </Box>
                        <Box className='flex items-center gap-2 bg-white/10 backdrop-blur-md px-4 py-2 rounded-full border border-white/10'>
                            <i className='ri-time-line text-blue-300' />
                            <Typography className='text-sm font-medium uppercase'>
                                {new Date().toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long' })}
                            </Typography>
                        </Box>
                    </CardContent>
                </Card>
            </Grid>

            {/* Summary Pie Chart - Refactored to separate component */}
            <Grid item xs={12} md={5}>
                <AttendanceSummaryPie summary={summary} onRefresh={fetchData} />
            </Grid>

            {/* Performance Trend Chart - Refactored to separate component */}
            <Grid item xs={12} md={7}>
                <AttendanceTrendLine trend={trend} />
            </Grid>

            {/* Quick Actions */}
            <Grid item xs={12}>
                <Box className='grid grid-cols-2 sm:grid-cols-4 gap-4'>
                    {quickActions.map((action, idx) => (
                        <Link key={idx} href={action.url} className='block no-underline'>
                            <Card className='shadow-md rounded-2xl border-none hover:translate-y-[-4px] transition-all cursor-pointer'>
                                <CardContent className='p-4 flex flex-col items-center gap-3'>
                                    <Box className={`p-4 rounded-full ${action.color}`}>
                                        <i className={`${action.icon} text-2xl`} />
                                    </Box>
                                    <Typography className='font-bold text-xs uppercase tracking-wider text-slate-700'>{action.label}</Typography>
                                </CardContent>
                            </Card>
                        </Link>
                    ))}
                </Box>
            </Grid>

            {/* Management & Invites */}
            <Grid item xs={12} md={8}>
                <Grid container spacing={4}>
                    <Grid item xs={12} sm={6}>
                         <Link href='/absensi' className='block no-underline h-full'>
                            <Card className='shadow-lg rounded-2xl border-none h-full hover:shadow-xl transition-all cursor-pointer'>
                                <CardContent className='flex items-center gap-5'>
                                    <Box className='bg-purple-100 p-4 rounded-xl text-purple-600'>
                                        <i className='ri-file-list-3-line text-2xl' />
                                    </Box>
                                    <Box>
                                        <Typography className='font-bold text-slate-800'>Laporan Kehadiran</Typography>
                                        <Typography variant='caption' className='text-slate-400'>Ekspor Excel & Riwayat Lengkap</Typography>
                                    </Box>
                                </CardContent>
                            </Card>
                         </Link>
                    </Grid>
                    <Grid item xs={12} sm={6}>
                         <Link href='/payroll' className='block no-underline h-full'>
                            <Card className='shadow-lg rounded-2xl border-none h-full hover:shadow-xl transition-all cursor-pointer'>
                                <CardContent className='flex items-center gap-5'>
                                    <Box className='bg-emerald-100 p-4 rounded-xl text-emerald-600'>
                                        <i className='ri-money-dollar-box-line text-2xl' />
                                    </Box>
                                    <Box>
                                        <Typography className='font-bold text-slate-800'>Manajemen Gaji</Typography>
                                        <Typography variant='caption' className='text-slate-400'>Proses Pembayaran & Potongan</Typography>
                                    </Box>
                                </CardContent>
                            </Card>
                         </Link>
                    </Grid>
                    <Grid item xs={12}>
                        <Card className='shadow-lg rounded-2xl border-none bg-slate-900 border border-slate-100 p-2'>
                            <CardContent className='flex flex-col sm:flex-row items-center justify-between gap-6'>
                                <Box className='flex items-center gap-5'>
                                    <Box className='bg-white/10 p-4 rounded-xl text-white'>
                                        <i className='ri-qr-code-line text-3xl' />
                                    </Box>
                                    <Box>
                                        <Typography className='font-bold text-white'>Undangan Rekrutmen</Typography>
                                        <Typography variant='caption' className='text-white/50'>Barcode baru akan diperbarui tiap 30 detik</Typography>
                                    </Box>
                                </Box>
                                <Button 
                                    variant='contained' 
                                    className='rounded-xl shadow-none bg-blue-600 hover:bg-blue-700 h-[50px] px-8 text-white'
                                    startIcon={<i className='ri-qr-scan-2-line' />}
                                    onClick={() => setQrModalOpen(true)}
                                >
                                    Lihat Barcode
                                </Button>
                            </CardContent>
                        </Card>
                    </Grid>
                </Grid>
            </Grid>

            {/* Sidebar Stats & Percentage */}
            <Grid item xs={12} md={4}>
                <Card className='shadow-md rounded-2xl border-none h-full bg-blue-50'>
                    <CardContent className='p-6'>
                        <Typography className='font-bold mbe-4 flex items-center gap-2'>
                            <i className='ri-notification-badge-line text-blue-600' />
                            Statistik Persentase
                        </Typography>
                        <Box className='space-y-4'>
                            <Box className='p-3 bg-white rounded-xl shadow-sm'>
                                <Typography variant='caption' className='text-slate-400'>Kehadiran (Presentase)</Typography>
                                <Box className='flex items-center justify-between mbs-1'>
                                    <Typography className='font-bold text-green-600'>
                                        {summary && summary.total > 0 ? ((summary.present / summary.total) * 100).toFixed(1) : 0}%
                                    </Typography>
                                    <Typography variant='caption' className='bg-green-100 text-green-700 px-2 py-0.5 rounded uppercase font-bold'>Positif</Typography>
                                </Box>
                            </Box>
                            <Box className='p-3 bg-white rounded-xl shadow-sm'>
                                <Typography variant='caption' className='text-slate-400'>Keterlambatan (Rasio)</Typography>
                                <Box className='flex items-center justify-between mbs-1'>
                                    <Typography className='font-bold text-amber-600'>
                                        {summary && summary.total > 0 ? ((summary.late / summary.total) * 100).toFixed(1) : 0}%
                                    </Typography>
                                    <Typography variant='caption' className='bg-amber-100 text-amber-700 px-2 py-0.5 rounded uppercase font-bold'>Waspada</Typography>
                                </Box>
                            </Box>
                            <Box className='p-3 bg-white rounded-xl shadow-sm'>
                                <Typography variant='caption' className='text-slate-400'>Rasio Alpha</Typography>
                                <Box className='flex items-center justify-between mbs-1'>
                                    <Typography className='font-bold text-red-600'>
                                        {summary && summary.total > 0 ? ((summary.absent / summary.total) * 100).toFixed(1) : 0}%
                                    </Typography>
                                    <Typography variant='caption' className='bg-red-100 text-red-700 px-2 py-0.5 rounded uppercase font-bold'>Kritis</Typography>
                                </Box>
                            </Box>
                        </Box>
                        <Link href='/analitik-absensi' className='block no-underline'>
                            <Button fullWidth variant='outlined' className='mbs-6 border-blue-200 text-blue-600 rounded-xl font-bold'>
                                Lihat Analitik
                            </Button>
                        </Link>
                    </CardContent>
                </Card>
            </Grid>

            {/* Recent Attendance Table */}
            <Grid item xs={12}>
                <RecentAttendanceTable />
            </Grid>

            {/* QR Modal */}
            <InviteQRModal open={qrModalOpen} onClose={() => setQrModalOpen(false)} />
        </Grid>
    )
}

export default MainAdminDashboard
