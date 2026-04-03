import { redirect } from 'next/navigation'

export default function RootPage() {
  redirect('/dashboard') // Or wherever the default dashboard is
}
