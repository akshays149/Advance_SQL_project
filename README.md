# Netflix Movies and TV Shows Data Analysis using SQL

<img width="2226" height="678" alt="logo" src="https://github.com/user-attachments/assets/010821a7-f988-48c2-a092-f21e3c1facf6" />


## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
	show_id	VARCHAR(max),
	type    VARCHAR(max),
	title	VARCHAR(max),
	director VARCHAR(max),
	casts	VARCHAR(max),
	country	VARCHAR(max),
	date_added	date,
	release_year	INT,
	rating	VARCHAR(255),
	duration	VARCHAR(255),
	listed_in	VARCHAR(255),
	description VARCHAR(max)
);
```
``imported data directly with wizard 
```sql
select * from netflix;
```
## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
select type, count(*) as total_count from netflix
group by type;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
select 
type,rating from
		(select rating, type, count(type) as common_rating, 
		rank() over (partition by type order by count(type)desc ) as max_rate
		from netflix 
		group by rating,type) as t1
where max_rate =1;
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
select title, type, release_year  from netflix
where release_year = 2020
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
select top 5 c_rank, count(show_id) as top_shows from
		(select show_id, value as c_rank from netflix
		cross apply   string_split(country,',')) as t2
group by c_rank
order by top_shows desc;
```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
with cte as (select title,type, duration, 
			cast(REPLACE(duration,' min',0)as int ) as new_duration from netflix
			where type = 'movie')

select * from cte
where new_duration = (select max(cast(replace(duration,' min',0)as int )) from netflix
					  where type ='movie');
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
with cte as (select show_id, title, type, 
			 datediff(year,date_added,getdate()) as last_5yrs 
			 from netflix)

select * from cte
where last_5yrs between 0 and 5;
```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
with cte as (select show_id, type,title,value as indi_directors from netflix
			 cross apply string_split(director,','))

select * from cte 
where indi_directors ='rajiv chilaka';

--second way of doing this 

select * from netflix
where director like'%Rajiv chilaka%';
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
 with cte as (select show_id, type,  title, 
			  try_cast(replace(replace(duration,' season',''),'s','')as int) as seasons from netflix
			  where type = 'tv show')

select * from cte
where seasons > 5;
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
select count(show_id) as count_content, value as genre from netflix
cross apply string_split(listed_in,',')
group by value;
```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

```sql
with content_counts as (select release_year, count(show_id) as total_release from netflix
						cross apply string_split(country, ',')
						where trim(value) = 'india'
						group by release_year)
select top 5 
    release_year, 
    total_release,
    (select avg(cast(total_release as float)) from content_counts) as avg_release
from content_counts
order by total_release desc;
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
select title, type, value as genre from netflix
cross apply string_split(listed_in,',')
where type = 'movie'
and value = 'documentaries';

--another way 

select * from netflix
where listed_in like '%documentaries%'
and type ='movie';
```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
select title, type , director from netflix
where director is null;
```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
select count(title) as no_movies , release_year, year(getdate())-release_year from netflix
where cast like '%salman khan%'
and type = 'movie'
group by release_year
having   year(getdate())-release_year <= 10;
```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
select top 10 count(title) as no_work, type,  country,  value as actors 
from netflix
cross apply string_split(cast,',')
where country like 'india'
and type = 'movie'
group by value,type,country
order by no_work desc;
```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
select count(title), 
	CASE
		when description like '%kill%'		then 'Bad'
		when description like '%violence%'  then 'Bad'
		else 'Good'
		END as categorize
from netflix
group by 	case	when description like '%kill%'		then 'Bad'
		when description like '%violence%'  then 'Bad'
		else 'Good'
		END; 
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.




