export type ClassType = 'Lecture' | 'Section' | 'Practical' | 'Lab';

export interface StudentProfile {
  name: string;
  email: string;
  phone: string;
  year: string;
  group: string;
  section: string;
  initials: string;
}

export interface Subject {
  id: string;
  name: string;
  code: string;
  description: string;
  color: string;
  icon: string;
  status: 'Active' | 'Upcoming';
  year: string;
  lecturer: string;
  progress: number;
  topics: string[];
}

export interface ScheduleItem {
  id: string;
  subjectId: string;
  subject: string;
  type: ClassType;
  start: string;
  end: string;
  location: string;
  dateLabel: string;
  day: 'Today' | 'Tomorrow' | 'Weekly' | 'Upcoming';
  color: string;
  room: string;
}

export interface NotificationItem {
  id: string;
  title: string;
  body: string;
  time: string;
  kind: 'Lecture' | 'Announcement' | 'System';
  unread: boolean;
}

export interface OwnerMetric {
  label: string;
  value: string;
  trend: string;
  icon: string;
  tone: string;
}

export const student: StudentProfile = {
  name: 'Omar Hassan',
  email: 'omar.hassan@acadmind.edu',
  phone: '+20 100 246 7819',
  year: 'First Year',
  group: 'G1',
  section: 'Sec 3',
  initials: 'OH'
};

export const subjects: Subject[] = [
  {
    id: 'physics', name: 'Physics', code: 'PHY 101', description: 'Build a practical understanding of motion, energy, and the world around you.',
    color: '#16b8a6', icon: 'atom', status: 'Active', year: 'First Year', lecturer: 'Dr. Lina Samir', progress: 68,
    topics: ['Kinematics', 'Newton’s Laws', 'Work & Energy', 'Momentum']
  },
  {
    id: 'mathematics', name: 'Mathematics', code: 'MTH 101', description: 'Core mathematical thinking for confident university problem solving.',
    color: '#7c72e8', icon: 'sigma', status: 'Active', year: 'First Year', lecturer: 'Dr. Karim Adel', progress: 54,
    topics: ['Functions', 'Limits', 'Derivatives', 'Vectors']
  },
  {
    id: 'programming', name: 'Programming Fundamentals', code: 'CS 101', description: 'Learn to turn ideas into reliable, readable code through fundamentals.',
    color: '#f29c58', icon: 'code', status: 'Active', year: 'First Year', lecturer: 'Eng. Youssef Nabil', progress: 42,
    topics: ['Variables', 'Control Flow', 'Functions', 'Data Structures']
  },
  {
    id: 'chemistry', name: 'General Chemistry', code: 'CHM 101', description: 'Explore the structure of matter and the patterns behind reactions.',
    color: '#ef6f9f', icon: 'flask', status: 'Upcoming', year: 'First Year', lecturer: 'Dr. Salma Nassar', progress: 26,
    topics: ['Atomic Structure', 'Periodic Table', 'Bonding', 'Reactions']
  }
];

export const schedule: ScheduleItem[] = [
  { id: 's1', subjectId: 'physics', subject: 'Physics', type: 'Lecture', start: '10:00', end: '11:30', location: 'Science Hall', room: 'A-204', dateLabel: 'Today', day: 'Today', color: '#16b8a6' },
  { id: 's2', subjectId: 'mathematics', subject: 'Mathematics', type: 'Section', start: '12:00', end: '13:00', location: 'North Wing', room: 'B-110', dateLabel: 'Today', day: 'Today', color: '#7c72e8' },
  { id: 's3', subjectId: 'programming', subject: 'Programming Fundamentals', type: 'Practical', start: '14:30', end: '16:00', location: 'Innovation Lab', room: 'Lab 02', dateLabel: 'Today', day: 'Today', color: '#f29c58' },
  { id: 's4', subjectId: 'chemistry', subject: 'General Chemistry', type: 'Lab', start: '09:00', end: '11:00', location: 'Chemistry Block', room: 'C-012', dateLabel: 'Tomorrow', day: 'Tomorrow', color: '#ef6f9f' },
  { id: 's5', subjectId: 'physics', subject: 'Physics', type: 'Section', start: '11:30', end: '12:30', location: 'Science Hall', room: 'A-110', dateLabel: 'Tomorrow', day: 'Tomorrow', color: '#16b8a6' },
  { id: 's6', subjectId: 'mathematics', subject: 'Mathematics', type: 'Lecture', start: '08:30', end: '10:00', location: 'Main Auditorium', room: 'MA-01', dateLabel: 'Mon, 30 Nov', day: 'Upcoming', color: '#7c72e8' }
];

export const notifications: NotificationItem[] = [
  { id: 'n1', title: 'Physics lecture starts in 10 minutes', body: 'Science Hall · Room A-204', time: 'Today, 09:50', kind: 'Lecture', unread: true },
  { id: 'n2', title: 'New resource added to Mathematics', body: 'Limits & continuity revision sheet is ready.', time: 'Yesterday, 17:20', kind: 'Announcement', unread: true },
  { id: 'n3', title: 'Schedule updated', body: 'Your Chemistry lab moved to C-012.', time: 'Nov 24, 12:40', kind: 'System', unread: false },
  { id: 'n4', title: 'Welcome to AcadMind', body: 'Your academic workspace is ready to explore.', time: 'Nov 22, 09:10', kind: 'System', unread: false }
];

export const ownerMetrics: OwnerMetric[] = [
  { label: 'Active students', value: '1,248', trend: '+8.4%', icon: 'users', tone: 'mint' },
  { label: 'Published subjects', value: '24', trend: '+2 this month', icon: 'book', tone: 'violet' },
  { label: 'Upcoming lectures', value: '186', trend: 'Across 6 years', icon: 'calendar', tone: 'orange' },
  { label: 'Unread reports', value: '07', trend: 'Needs review', icon: 'flag', tone: 'rose' }
];

export const ownerRows = [
  { title: 'Physics · PHY 101', meta: 'First Year · Updated 2h ago', status: 'Published', tone: 'mint' },
  { title: 'Welcome announcement', meta: 'All students · Updated yesterday', status: 'Scheduled', tone: 'violet' },
  { title: 'Semester 1 timetable', meta: 'G1 / Sec 1–6 · Updated Nov 24', status: 'Published', tone: 'mint' }
];
