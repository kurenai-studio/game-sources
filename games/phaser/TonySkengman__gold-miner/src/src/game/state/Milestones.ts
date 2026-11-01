export interface Milestone {
    fraction: number;
    kind: 'money' | 'dynamite';
    amount: number;
    label: string;
}

export const MILESTONES: readonly Milestone[] = [
    { fraction: 1.5, kind: 'money', amount: 150, label: '+$150' },
    { fraction: 1.75, kind: 'money', amount: 400, label: '+$400' },
    { fraction: 2, kind: 'dynamite', amount: 1, label: '+1 DYNAMITE' }
];
