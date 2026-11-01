import type { LevelStatus } from "@/lib/admin/admin-api";
import { Field, SelectField } from "../ui";

export type Sort = "updatedAt" | "title" | "slug" | "createdAt";
export type Filters = {
  q: string;
  status: "" | LevelStatus;
  placement: "" | "unassigned";
  sort: Sort;
};

/** Search, status, placement and sort. Any change resets paging through `onChange`. */
export function LevelFilters({
  filters,
  onChange,
}: {
  filters: Filters;
  onChange: (next: Partial<Filters>) => void;
}) {
  return (
    <form
      role="search"
      aria-label="Filter levels"
      onSubmit={(e) => e.preventDefault()}
      className="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4"
    >
      <Field
        label="Search"
        id="level-search"
        type="search"
        value={filters.q}
        onChange={(e) => onChange({ q: e.target.value })}
        placeholder="Title or slug"
        autoComplete="off"
      />
      <SelectField
        label="Status"
        id="level-status"
        value={filters.status}
        onChange={(e) => onChange({ status: e.target.value as Filters["status"] })}
      >
        <option value="">All</option>
        <option value="DRAFT">Draft</option>
        <option value="PUBLISHED">Published</option>
        <option value="ARCHIVED">Archived</option>
      </SelectField>
      <SelectField
        label="Placement"
        id="level-placement"
        value={filters.placement}
        onChange={(e) => onChange({ placement: e.target.value as Filters["placement"] })}
      >
        <option value="">All</option>
        <option value="unassigned">Unassigned only</option>
      </SelectField>
      <SelectField
        label="Sort"
        id="level-sort"
        value={filters.sort}
        onChange={(e) => onChange({ sort: e.target.value as Sort })}
      >
        <option value="updatedAt">Last updated</option>
        <option value="createdAt">Created</option>
        <option value="title">Title</option>
        <option value="slug">Slug</option>
      </SelectField>
    </form>
  );
}
